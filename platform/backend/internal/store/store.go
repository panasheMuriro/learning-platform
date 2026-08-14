// Package store is the GORM-backed progress and course-registry store.
//
// It uses GORM for ORM-style CRUD with auto-migration (no hand-written SQL
// migration files). All progress tables are keyed by course_id so progress is
// isolated per course. Single-user for now (no user_id); a column can be added
// later without restructuring.
//
// The store also owns the courses registry table, which is populated at
// startup by the registry package (see internal/registry).
package store

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// Model definitions — GORM auto-migrates these into tables.

// Course is a registered course (DB row). Populated at startup by the registry.
type Course struct {
	ID          string `gorm:"primaryKey" json:"id"`
	Slug        string `gorm:"uniqueIndex" json:"slug"`
	Title       string `json:"title"`
	Summary     string `json:"summary"`
	Icon        string `json:"icon"`
	Version     string `json:"version"`
	Workspace   string `json:"workspace"` // "code-server" (default) or "terminal"
	ContentPath string `json:"-"`
	Enabled     bool   `gorm:"default:true" json:"enabled"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

// QuizResult stores a quiz score for one (course, module).
type QuizResult struct {
	CourseID  string `gorm:"primaryKey" json:"-"`
	ModuleID  string `gorm:"primaryKey" json:"-"`
	Score     int    `json:"score"`
	Passed    bool   `json:"passed"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// LabResult marks a lab as completed for one (course, module, lab).
type LabResult struct {
	CourseID  string `gorm:"primaryKey" json:"-"`
	ModuleID  string `gorm:"primaryKey" json:"-"`
	LabID     string `gorm:"primaryKey" json:"-"`
	Completed bool   `gorm:"default:true" json:"completed"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// LabTaskResult marks an individual task as passed for one (course, module, lab, task).
type LabTaskResult struct {
	CourseID  string `gorm:"primaryKey" json:"-"`
	ModuleID  string `gorm:"primaryKey" json:"-"`
	LabID     string `gorm:"primaryKey" json:"-"`
	TaskID    string `gorm:"primaryKey" json:"taskId"`
	Passed    bool   `gorm:"default:true" json:"passed"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// LectureProgress marks a lecture as completed for one (course, module, lecture).
type LectureProgress struct {
	CourseID  string `gorm:"primaryKey" json:"-"`
	ModuleID  string `gorm:"primaryKey" json:"-"`
	LectureID string `gorm:"primaryKey" json:"-"`
	Completed bool   `gorm:"default:true" json:"completed"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// Store is the GORM-backed store.
type Store struct {
	db *gorm.DB
}

// Open connects to Postgres at dsn, auto-migrates all models, and returns a Store.
func Open(dsn string) (*Store, error) {
	gormLogLevel := logger.Warn
	if os.Getenv("DB_LOG") == "debug" {
		gormLogLevel = logger.Info
	}

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(gormLogLevel),
	})
	if err != nil {
		return nil, fmt.Errorf("connect postgres: %w", err)
	}

	// Auto-migrate all models — GORM creates/updates tables from the structs.
	if err := db.AutoMigrate(
		&Course{},
		&QuizResult{},
		&LabResult{},
		&LectureProgress{},
		&LabTaskResult{},
	); err != nil {
		return nil, fmt.Errorf("auto-migrate: %w", err)
	}

	return &Store{db: db}, nil
}

// Close releases the database connection.
func (s *Store) Close() error {
	sqlDB, err := s.db.DB()
	if err != nil {
		return err
	}
	return sqlDB.Close()
}

// DB returns the underlying *gorm.DB (used by the registry package).
func (s *Store) DB() *gorm.DB {
	return s.db
}

// ---- Course registry methods ----

// UpsertCourse inserts or updates a course row (matched by ID).
func (s *Store) UpsertCourse(c Course) error {
	return s.db.Save(&c).Error
}

// DeleteCourse removes a course row by ID. Used to clean up courses that
// no longer exist on disk.
func (s *Store) DeleteCourse(courseID string) error {
	return s.db.Where("id = ?", courseID).Delete(&Course{}).Error
}

// ListCourses returns all enabled courses, ordered by title.
func (s *Store) ListCourses() ([]Course, error) {
	var courses []Course
	err := s.db.Where("enabled = ?", true).Order("title").Find(&courses).Error
	return courses, err
}

// ListAllCourses returns all courses (including disabled), ordered by title.
// Used by the registry to detect stale entries.
func (s *Store) ListAllCourses() ([]Course, error) {
	var courses []Course
	err := s.db.Order("title").Find(&courses).Error
	return courses, err
}

// GetCourse returns a single course by its slug or id. Returns nil if not found.
func (s *Store) GetCourse(slugOrID string) (*Course, error) {
	var c Course
	err := s.db.Where("slug = ? OR id = ?", slugOrID, slugOrID).First(&c).Error
	if err != nil {
		return nil, err // gorm.ErrRecordNotFound if not found
	}
	return &c, nil
}

// ---- Progress methods ----

// RecordQuiz stores a quiz result for a course+module (upsert).
func (s *Store) RecordQuiz(courseID, moduleID string, score int, passed bool) error {
	result := QuizResult{
		CourseID: courseID,
		ModuleID: moduleID,
		Score:    score,
		Passed:   passed,
	}
	return s.db.Save(&result).Error
}

// RecordLab marks a lab as completed for a course+module+lab (upsert).
func (s *Store) RecordLab(courseID, moduleID, labID string) error {
	result := LabResult{
		CourseID:  courseID,
		ModuleID:  moduleID,
		LabID:     labID,
		Completed: true,
	}
	return s.db.Save(&result).Error
}

// RecordLecture marks a lecture as completed for a course+module+lecture (upsert).
func (s *Store) RecordLecture(courseID, moduleID, lectureID string) error {
	result := LectureProgress{
		CourseID:  courseID,
		ModuleID:  moduleID,
		LectureID: lectureID,
		Completed: true,
	}
	return s.db.Save(&result).Error
}

// UnrecordLecture removes lecture progress for a course+module+lecture.
func (s *Store) UnrecordLecture(courseID, moduleID, lectureID string) error {
	return s.db.Where("course_id = ? AND module_id = ? AND lecture_id = ?",
		courseID, moduleID, lectureID).Delete(&LectureProgress{}).Error
}

// UnrecordLab removes lab progress for a course+module+lab.
func (s *Store) UnrecordLab(courseID, moduleID, labID string) error {
	return s.db.Where("course_id = ? AND module_id = ? AND lab_id = ?",
		courseID, moduleID, labID).Delete(&LabResult{}).Error
}

// UnrecordQuiz removes quiz progress for a course+module.
func (s *Store) UnrecordQuiz(courseID, moduleID string) error {
	return s.db.Where("course_id = ? AND module_id = ?",
		courseID, moduleID).Delete(&QuizResult{}).Error
}

// ResetCourseProgress deletes all progress for a course (lectures, quizzes,
// labs, and lab tasks). Used when a learner wants to start over.
func (s *Store) ResetCourseProgress(courseID string) error {
	return s.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("course_id = ?", courseID).Delete(&LectureProgress{}).Error; err != nil {
			return err
		}
		if err := tx.Where("course_id = ?", courseID).Delete(&QuizResult{}).Error; err != nil {
			return err
		}
		if err := tx.Where("course_id = ?", courseID).Delete(&LabResult{}).Error; err != nil {
			return err
		}
		if err := tx.Where("course_id = ?", courseID).Delete(&LabTaskResult{}).Error; err != nil {
			return err
		}
		return nil
	})
}

// ---- Progress response types (kept compatible with the frontend) ----

// ProgressResponse is the full progress state for one course.
type ProgressResponse struct {
	Modules []ModuleProgress `json:"modules"`
}

// ModuleProgress is the progress for a single module within a course.
type ModuleProgress struct {
	ModuleID          string            `json:"moduleId"`
	LecturesCompleted []string          `json:"lecturesCompleted"`
	QuizPassed        bool              `json:"quizPassed"`
	QuizScore         *int              `json:"quizScore"`
	LabsCompleted     []string          `json:"labsCompleted"`
	TasksCompleted    map[string][]string `json:"tasksCompleted"`
}

// GetProgress returns all progress for a course.
func (s *Store) GetProgress(courseID string) (ProgressResponse, error) {
	resp := ProgressResponse{Modules: []ModuleProgress{}}

	// Quiz results
	var quizzes []QuizResult
	if err := s.db.Where("course_id = ?", courseID).Find(&quizzes).Error; err != nil {
		return resp, err
	}

	// Lab results
	var labs []LabResult
	if err := s.db.Where("course_id = ? AND completed = ?", courseID, true).Find(&labs).Error; err != nil {
		return resp, err
	}

	// Lecture progress
	var lectures []LectureProgress
	if err := s.db.Where("course_id = ? AND completed = ?", courseID, true).Find(&lectures).Error; err != nil {
		return resp, err
	}

	// Lab task results
	var taskResults []LabTaskResult
	if err := s.db.Where("course_id = ? AND passed = ?", courseID, true).Find(&taskResults).Error; err != nil {
		return resp, err
	}

	// Assemble into response
	modules := make(map[string]*ModuleProgress)
	for _, q := range quizzes {
		mp := modules[q.ModuleID]
		if mp == nil {
			mp = &ModuleProgress{ModuleID: q.ModuleID}
			modules[q.ModuleID] = mp
		}
		mp.QuizPassed = q.Passed
		score := q.Score
		mp.QuizScore = &score
	}
	for _, l := range labs {
		mp := modules[l.ModuleID]
		if mp == nil {
			mp = &ModuleProgress{ModuleID: l.ModuleID}
			modules[l.ModuleID] = mp
		}
		mp.LabsCompleted = append(mp.LabsCompleted, l.LabID)
	}
	for _, l := range lectures {
		mp := modules[l.ModuleID]
		if mp == nil {
			mp = &ModuleProgress{ModuleID: l.ModuleID}
			modules[l.ModuleID] = mp
		}
		mp.LecturesCompleted = append(mp.LecturesCompleted, l.LectureID)
	}
	for _, t := range taskResults {
		mp := modules[t.ModuleID]
		if mp == nil {
			mp = &ModuleProgress{ModuleID: t.ModuleID}
			modules[t.ModuleID] = mp
		}
		if mp.TasksCompleted == nil {
			mp.TasksCompleted = make(map[string][]string)
		}
		mp.TasksCompleted[t.LabID] = append(mp.TasksCompleted[t.LabID], t.TaskID)
	}

	for _, mp := range modules {
		if mp.LecturesCompleted == nil {
			mp.LecturesCompleted = []string{}
		}
		if mp.LabsCompleted == nil {
			mp.LabsCompleted = []string{}
		}
		if mp.TasksCompleted == nil {
			mp.TasksCompleted = make(map[string][]string)
		}
		resp.Modules = append(resp.Modules, *mp)
	}
	return resp, nil
}

// RecordLabTask marks a single lab task as passed (upsert).
func (s *Store) RecordLabTask(courseID, moduleID, labID, taskID string) error {
	result := LabTaskResult{
		CourseID: courseID,
		ModuleID: moduleID,
		LabID:    labID,
		TaskID:   taskID,
		Passed:   true,
	}
	return s.db.Save(&result).Error
}

// HandleGetProgress is the HTTP handler for GET /api/courses/{courseId}/progress.
func (s *Store) HandleGetProgress(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	resp, err := s.GetProgress(courseID)
	if err != nil {
		log.Printf("progress query error: %v", err)
		http.Error(w, "failed to query progress", http.StatusInternalServerError)
		return
	}
	writeJSON(w, resp)
}

// HandleMarkLectureComplete is the HTTP handler for
// POST /api/courses/{courseId}/modules/{moduleId}/lectures/{lectureId}/complete.
// It marks a lecture as completed (idempotent upsert) and returns the updated
// progress for the course so the client can refresh without a second round-trip.
func (s *Store) HandleMarkLectureComplete(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	moduleID := r.PathValue("moduleId")
	lectureID := r.PathValue("lectureId")

	if err := s.RecordLecture(courseID, moduleID, lectureID); err != nil {
		log.Printf("record lecture error: %v", err)
		http.Error(w, "failed to record lecture progress", http.StatusInternalServerError)
		return
	}

	resp, err := s.GetProgress(courseID)
	if err != nil {
		log.Printf("progress query error after lecture mark: %v", err)
		http.Error(w, "failed to query progress", http.StatusInternalServerError)
		return
	}
	writeJSON(w, resp)
}

// HandleUnmarkLecture is the HTTP handler for
// DELETE /api/courses/{courseId}/modules/{moduleId}/lectures/{lectureId}/complete.
// It removes lecture progress and returns the updated course progress.
func (s *Store) HandleUnmarkLecture(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	moduleID := r.PathValue("moduleId")
	lectureID := r.PathValue("lectureId")

	if err := s.UnrecordLecture(courseID, moduleID, lectureID); err != nil {
		log.Printf("unrecord lecture error: %v", err)
		http.Error(w, "failed to unrecord lecture progress", http.StatusInternalServerError)
		return
	}

	resp, err := s.GetProgress(courseID)
	if err != nil {
		log.Printf("progress query error after lecture unmark: %v", err)
		http.Error(w, "failed to query progress", http.StatusInternalServerError)
		return
	}
	writeJSON(w, resp)
}

// HandleUnmarkLab is the HTTP handler for
// DELETE /api/courses/{courseId}/modules/{moduleId}/labs/{labId}/complete.
// It removes lab progress and returns the updated course progress.
func (s *Store) HandleUnmarkLab(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	moduleID := r.PathValue("moduleId")
	labID := r.PathValue("labId")

	if err := s.UnrecordLab(courseID, moduleID, labID); err != nil {
		log.Printf("unrecord lab error: %v", err)
		http.Error(w, "failed to unrecord lab progress", http.StatusInternalServerError)
		return
	}

	resp, err := s.GetProgress(courseID)
	if err != nil {
		log.Printf("progress query error after lab unmark: %v", err)
		http.Error(w, "failed to query progress", http.StatusInternalServerError)
		return
	}
	writeJSON(w, resp)
}

// HandleUnmarkQuiz is the HTTP handler for
// DELETE /api/courses/{courseId}/modules/{moduleId}/quiz/complete.
// It removes quiz progress and returns the updated course progress.
func (s *Store) HandleUnmarkQuiz(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	moduleID := r.PathValue("moduleId")

	if err := s.UnrecordQuiz(courseID, moduleID); err != nil {
		log.Printf("unrecord quiz error: %v", err)
		http.Error(w, "failed to unrecord quiz progress", http.StatusInternalServerError)
		return
	}

	resp, err := s.GetProgress(courseID)
	if err != nil {
		log.Printf("progress query error after quiz unmark: %v", err)
		http.Error(w, "failed to query progress", http.StatusInternalServerError)
		return
	}
	writeJSON(w, resp)
}

// HandleResetCourseProgress is the HTTP handler for
// DELETE /api/courses/{courseId}/progress.
// It deletes all progress for the course and returns the empty progress state.
func (s *Store) HandleResetCourseProgress(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")

	if err := s.ResetCourseProgress(courseID); err != nil {
		log.Printf("reset course progress error: %v", err)
		http.Error(w, "failed to reset course progress", http.StatusInternalServerError)
		return
	}

	writeJSON(w, ProgressResponse{Modules: []ModuleProgress{}})
}

// ---- Helpers ----

// DefaultDSN returns a sensible Postgres DSN from the environment or a default.
func DefaultDSN() string {
	if dsn := os.Getenv("DATABASE_URL"); dsn != "" {
		return dsn
	}
	if dsn := os.Getenv("DB_DSN"); dsn != "" {
		return dsn
	}
	return "postgres://course:course@localhost:5432/course?sslmode=disable"
}

// ParseDSNHostPort extracts host and port from a postgres:// DSN for health
// logging. Returns ("", "") if it can't be parsed.
func ParseDSNHostPort(dsn string) (string, string) {
	u, err := url.Parse(dsn)
	if err != nil || u.Host == "" {
		return "", ""
	}
	host := u.Hostname()
	port := u.Port()
	if port == "" {
		port = "5432"
	}
	return host, port
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
