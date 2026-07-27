// Package content serves course content (lecture notes, quizzes, lab instructions)
// from the filesystem.
//
// Content layout (per course, under <content-root>/courses/<course-slug>/):
//
//	courses/<course-slug>/
//	  course.json              # course metadata
//	  outline.json             # course outline (modules, lectures, labs, quiz refs)
//	  module-01/
//	    notes/01-what-is-juju.md
//	    quiz.json
//	    lab-01-first-model-app/lab.md
//	    ...
//
// The service resolves a course's content directory via the registry (which
// reads course.json at startup and stores the content_path in the DB).
package content

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"

	"github.com/juju-tf-course/platform/backend/internal/registry"
)

// Service serves course content by resolving each course's content directory
// via the registry.
type Service struct {
	reg *registry.Registry
}

// NewService creates a content service backed by the given registry.
func NewService(reg *registry.Registry) *Service {
	return &Service{reg: reg}
}

// Outline is the top-level course structure.
type Outline struct {
	Title   string   `json:"title"`
	Modules []Module `json:"modules"`
}

// Module represents a course module.
type Module struct {
	ID       string       `json:"id"`
	Title    string       `json:"title"`
	Lectures []LectureRef `json:"lectures"`
	Labs     []LabRef     `json:"labs"`
	Quiz     *QuizRef     `json:"quiz,omitempty"`
}

// LectureRef is a reference to a lecture.
type LectureRef struct {
	ID    string `json:"id"`
	Title string `json:"title"`
}

// LabRef is a reference to a lab.
type LabRef struct {
	ID    string `json:"id"`
	Title string `json:"title"`
}

// QuizRef is a reference to a quiz.
type QuizRef struct {
	ID string `json:"id"`
}

// Question is a single multiple-choice or text-answer question.
type Question struct {
	ID          string   `json:"id"`
	Prompt      string   `json:"prompt"`
	Type        string   `json:"type"` // "single-choice", "multi-choice", "text-answer"
	Options     []string `json:"options,omitempty"`
	Answer      any      `json:"answer"` // string or []string
	Explanation string   `json:"explanation,omitempty"`
}

// Lecture is a full lecture with markdown content and optional review questions.
type Lecture struct {
	ID        string     `json:"id"`
	Title     string     `json:"title"`
	Markdown  string     `json:"markdown"`
	Questions []Question `json:"questions,omitempty"`
}

// LabTask is a single task inside a lab.
type LabTask struct {
	ID           string            `json:"id"`
	Title        string            `json:"title"`
	Instructions string            `json:"instructions"`
	Hints        []string          `json:"hints,omitempty"`
	Solution     string            `json:"solution,omitempty"`
	Check        string            `json:"check"`
	Workspace    map[string]string `json:"workspace,omitempty"`
}

// LabInstructions is a lab's instruction markdown and structured tasks.
type LabInstructions struct {
	ID       string    `json:"id"`
	Title    string    `json:"title"`
	Markdown string    `json:"markdown"`
	Tasks    []LabTask `json:"tasks,omitempty"`
}

// resolveCourse looks up a course by slug/id and returns its content directory.
// Writes a 404 and returns "" if the course is not found.
func (s *Service) resolveCourse(w http.ResponseWriter, r *http.Request, courseID string) string {
	course, err := s.reg.Get(courseID)
	if err != nil || course == nil {
		http.Error(w, "course not found", http.StatusNotFound)
		return ""
	}
	return course.ContentPath
}

// loadOutline reads and parses outline.json from a course's content directory.
func loadOutline(contentPath string) (*Outline, error) {
	data, err := os.ReadFile(filepath.Join(contentPath, "outline.json"))
	if err != nil {
		return nil, err
	}
	var outline Outline
	if err := json.Unmarshal(data, &outline); err != nil {
		return nil, err
	}
	return &outline, nil
}

// HandleOutline serves the course outline (GET /api/courses/{courseId}/outline).
func (s *Service) HandleOutline(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	contentPath := s.resolveCourse(w, r, courseID)
	if contentPath == "" {
		return
	}
	outline, err := loadOutline(contentPath)
	if err != nil {
		http.Error(w, "failed to load outline: "+err.Error(), http.StatusInternalServerError)
		return
	}
	writeJSON(w, outline)
}

// HandleLecture serves a single lecture
// (GET /api/courses/{courseId}/modules/{moduleId}/lectures/{lectureId}).
func (s *Service) HandleLecture(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	moduleID := r.PathValue("moduleId")
	lectureID := r.PathValue("lectureId")

	contentPath := s.resolveCourse(w, r, courseID)
	if contentPath == "" {
		return
	}

	// Find the lecture title from outline
	title := lectureID
	outline, err := loadOutline(contentPath)
	if err == nil {
		for _, mod := range outline.Modules {
			if mod.ID == moduleID {
				for _, lec := range mod.Lectures {
					if lec.ID == lectureID {
						title = lec.Title
					}
				}
			}
		}
	}

	mdPath := filepath.Join(contentPath, moduleID, "notes", lectureID+".md")
	md, err := os.ReadFile(mdPath)
	if err != nil {
		http.Error(w, "lecture not found", http.StatusNotFound)
		return
	}

	lecture := Lecture{ID: lectureID, Title: title, Markdown: string(md)}

	quizPath := filepath.Join(contentPath, moduleID, "notes", lectureID+".quiz.json")
	if data, err := os.ReadFile(quizPath); err == nil {
		var payload struct {
			Questions []Question `json:"questions"`
		}
		if err := json.Unmarshal(data, &payload); err == nil {
			lecture.Questions = payload.Questions
		}
	}

	writeJSON(w, lecture)
}

// HandleQuiz serves a module's quiz
// (GET /api/courses/{courseId}/modules/{moduleId}/quiz).
func (s *Service) HandleQuiz(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	moduleID := r.PathValue("moduleId")

	contentPath := s.resolveCourse(w, r, courseID)
	if contentPath == "" {
		return
	}

	quizPath := filepath.Join(contentPath, moduleID, "quiz.json")
	data, err := os.ReadFile(quizPath)
	if err != nil {
		http.Error(w, "quiz not found", http.StatusNotFound)
		return
	}

	// Return the quiz as-is (the quiz.json file is already in the right format)
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(data)
}

// HandleLab serves lab instructions
// (GET /api/courses/{courseId}/modules/{moduleId}/labs/{labId}).
func (s *Service) HandleLab(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	moduleID := r.PathValue("moduleId")
	labID := r.PathValue("labId")

	contentPath := s.resolveCourse(w, r, courseID)
	if contentPath == "" {
		return
	}

	// Find the lab title from outline
	outline, err := loadOutline(contentPath)
	if err != nil {
		http.Error(w, "lab not found", http.StatusNotFound)
		return
	}

	for _, mod := range outline.Modules {
		if mod.ID != moduleID {
			continue
		}
		for _, lab := range mod.Labs {
			if lab.ID != labID {
				continue
			}
			labDir := filepath.Join(contentPath, moduleID, labID)

			// Prefer structured tasks.json, fall back to lab.md.
			tasksPath := filepath.Join(labDir, "tasks.json")
			if data, err := os.ReadFile(tasksPath); err == nil {
				var payload struct {
					Tasks []LabTask `json:"tasks"`
				}
				if err := json.Unmarshal(data, &payload); err == nil && len(payload.Tasks) > 0 {
					writeJSON(w, LabInstructions{
						ID:    labID,
						Title: lab.Title,
						Tasks: payload.Tasks,
					})
					return
				}
			}

			mdPath := filepath.Join(labDir, "lab.md")
			md, err := os.ReadFile(mdPath)
			if err != nil {
				http.Error(w, "lab not found", http.StatusNotFound)
				return
			}
			writeJSON(w, LabInstructions{ID: labID, Title: lab.Title, Markdown: string(md)})
			return
		}
	}

	http.Error(w, "lab not found", http.StatusNotFound)
}

// ContentPathFor returns the filesystem content directory for a course.
// Used by other packages (quiz, grade, labseed) that need to read course files.
func (s *Service) ContentPathFor(courseID string) (string, bool) {
	course, err := s.reg.Get(courseID)
	if err != nil || course == nil {
		return "", false
	}
	return course.ContentPath, true
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
