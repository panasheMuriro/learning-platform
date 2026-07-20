// Package progress stores learner progress in a local SQLite database.
//
// Since the platform is fully local with no auth, there is a single local
// profile. Progress is keyed by module ID and lab ID.
package progress

import (
	"database/sql"
	"encoding/json"
	"net/http"

	_ "modernc.org/sqlite"
)

// Store is the SQLite-backed progress store.
type Store struct {
	db *sql.DB
}

// Open creates or opens a SQLite progress database.
func Open(path string) (*Store, error) {
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}

	// Create tables if they don't exist
	schema := `
	CREATE TABLE IF NOT EXISTS quiz_results (
		module_id  TEXT PRIMARY KEY,
		score      INTEGER NOT NULL,
		passed     BOOLEAN NOT NULL,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	CREATE TABLE IF NOT EXISTS lab_results (
		module_id  TEXT NOT NULL,
		lab_id     TEXT NOT NULL,
		completed  BOOLEAN NOT NULL DEFAULT TRUE,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		PRIMARY KEY (module_id, lab_id)
	);
	CREATE TABLE IF NOT EXISTS lecture_progress (
		module_id   TEXT NOT NULL,
		lecture_id  TEXT NOT NULL,
		completed   BOOLEAN NOT NULL DEFAULT TRUE,
		updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
		PRIMARY KEY (module_id, lecture_id)
	);
	`
	if _, err := db.Exec(schema); err != nil {
		db.Close()
		return nil, err
	}

	return &Store{db: db}, nil
}

// Close closes the database.
func (s *Store) Close() error {
	return s.db.Close()
}

// RecordQuiz stores a quiz result.
func (s *Store) RecordQuiz(moduleID string, score int, passed bool) error {
	_, err := s.db.Exec(
		`INSERT INTO quiz_results (module_id, score, passed) VALUES (?, ?, ?)
		 ON CONFLICT(module_id) DO UPDATE SET score=excluded.score, passed=excluded.passed, updated_at=CURRENT_TIMESTAMP`,
		moduleID, score, passed,
	)
	return err
}

// RecordLab marks a lab as completed.
func (s *Store) RecordLab(moduleID, labID string) error {
	_, err := s.db.Exec(
		`INSERT INTO lab_results (module_id, lab_id, completed) VALUES (?, ?, TRUE)
		 ON CONFLICT(module_id, lab_id) DO UPDATE SET completed=TRUE, updated_at=CURRENT_TIMESTAMP`,
		moduleID, labID,
	)
	return err
}

// RecordLecture marks a lecture as completed.
func (s *Store) RecordLecture(moduleID, lectureID string) error {
	_, err := s.db.Exec(
		`INSERT INTO lecture_progress (module_id, lecture_id, completed) VALUES (?, ?, TRUE)
		 ON CONFLICT(module_id, lecture_id) DO UPDATE SET completed=TRUE, updated_at=CURRENT_TIMESTAMP`,
		moduleID, lectureID,
	)
	return err
}

// ProgressResponse is the full progress state for the frontend.
type ProgressResponse struct {
	Modules []ModuleProgress `json:"modules"`
}

// ModuleProgress is the progress for a single module.
type ModuleProgress struct {
	ModuleID           string   `json:"moduleId"`
	LecturesCompleted  []string `json:"lecturesCompleted"`
	QuizPassed         bool     `json:"quizPassed"`
	QuizScore          *int     `json:"quizScore"`
	LabsCompleted      []string `json:"labsCompleted"`
}

// HandleGetProgress returns all progress (GET /api/progress).
func (s *Store) HandleGetProgress(w http.ResponseWriter, r *http.Request) {
	// Quiz results
	quizRows, err := s.db.Query(`SELECT module_id, score, passed FROM quiz_results`)
	if err != nil {
		http.Error(w, "failed to query progress", http.StatusInternalServerError)
		return
	}
	defer quizRows.Close()

	quizMap := make(map[string]struct {
		score  int
		passed bool
	})
	for quizRows.Next() {
		var modID string
		var score int
		var passed bool
		_ = quizRows.Scan(&modID, &score, &passed)
		quizMap[modID] = struct {
			score  int
			passed bool
		}{score, passed}
	}

	// Lab results
	labRows, err := s.db.Query(`SELECT module_id, lab_id FROM lab_results WHERE completed=TRUE`)
	if err != nil {
		http.Error(w, "failed to query labs", http.StatusInternalServerError)
		return
	}
	defer labRows.Close()

	labMap := make(map[string][]string)
	for labRows.Next() {
		var modID, labID string
		_ = labRows.Scan(&modID, &labID)
		labMap[modID] = append(labMap[modID], labID)
	}

	// Lecture progress
	lecRows, err := s.db.Query(`SELECT module_id, lecture_id FROM lecture_progress WHERE completed=TRUE`)
	if err != nil {
		http.Error(w, "failed to query lectures", http.StatusInternalServerError)
		return
	}
	defer lecRows.Close()

	lecMap := make(map[string][]string)
	for lecRows.Next() {
		var modID, lecID string
		_ = lecRows.Scan(&modID, &lecID)
		lecMap[modID] = append(lecMap[modID], lecID)
	}

	// Assemble response
	modules := make(map[string]*ModuleProgress)
	for modID, quiz := range quizMap {
		mp := modules[modID]
		if mp == nil {
			mp = &ModuleProgress{ModuleID: modID}
			modules[modID] = mp
		}
		mp.QuizPassed = quiz.passed
		score := quiz.score
		mp.QuizScore = &score
	}
	for modID, labs := range labMap {
		mp := modules[modID]
		if mp == nil {
			mp = &ModuleProgress{ModuleID: modID}
			modules[modID] = mp
		}
		mp.LabsCompleted = labs
	}
	for modID, lecs := range lecMap {
		mp := modules[modID]
		if mp == nil {
			mp = &ModuleProgress{ModuleID: modID}
			modules[modID] = mp
		}
		mp.LecturesCompleted = lecs
	}

	var resp ProgressResponse
	for _, mp := range modules {
		if mp.LecturesCompleted == nil {
			mp.LecturesCompleted = []string{}
		}
		if mp.LabsCompleted == nil {
			mp.LabsCompleted = []string{}
		}
		resp.Modules = append(resp.Modules, *mp)
	}
	if resp.Modules == nil {
		resp.Modules = []ModuleProgress{}
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(resp)
}
