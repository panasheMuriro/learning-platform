// Package content serves course content (lecture notes, quizzes, lab instructions)
// from the content/ directory on the filesystem.
//
// Content layout:
//
//	content/
//	  outline.json              # course outline (modules, lectures, labs, quiz refs)
//	  module-01/
//	    notes/01-what-is-juju.md
//	    quiz.json
//	    lab-01-first-model-app/lab.md
//	    ...
package content

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"

	"github.com/juju-tf-course/platform/backend/internal/labseed"
)

// Service serves course content from a content directory.
type Service struct {
	root   string
	seeder *labseed.Service
}

// NewService creates a content service rooted at the given directory.
// If seeder is non-nil, opening a lab (HandleLab) will automatically seed
// the learner's lab working directory with starter files the first time
// it's requested.
func NewService(root string, seeder *labseed.Service) *Service {
	return &Service{root: root, seeder: seeder}
}

// Root returns the content root directory path.
func (s *Service) Root() string {
	return s.root
}

// Outline is the top-level course structure.
type Outline struct {
	Title   string   `json:"title"`
	Modules []Module `json:"modules"`
}

// Module represents a course module.
type Module struct {
	ID       string      `json:"id"`
	Title    string      `json:"title"`
	Lectures []LectureRef `json:"lectures"`
	Labs     []LabRef    `json:"labs"`
	Quiz     *QuizRef    `json:"quiz,omitempty"`
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

// Lecture is a full lecture with markdown content.
type Lecture struct {
	ID       string `json:"id"`
	Title    string `json:"title"`
	Markdown string `json:"markdown"`
}

// LabInstructions is a lab's instruction markdown.
type LabInstructions struct {
	ID       string `json:"id"`
	Title    string `json:"title"`
	Markdown string `json:"markdown"`
}

// HandleOutline serves the course outline (GET /api/outline).
func (s *Service) HandleOutline(w http.ResponseWriter, r *http.Request) {
	outline, err := s.loadOutline()
	if err != nil {
		http.Error(w, "failed to load outline: "+err.Error(), http.StatusInternalServerError)
		return
	}
	writeJSON(w, outline)
}

// HandleLecture serves a single lecture (GET /api/modules/{moduleId}/lectures/{lectureId}).
func (s *Service) HandleLecture(w http.ResponseWriter, r *http.Request) {
	moduleID := r.PathValue("moduleId")
	lectureID := r.PathValue("lectureId")

	// Find the lecture title from outline
	outline, err := s.loadOutline()
	if err != nil {
		http.Error(w, "failed to load outline", http.StatusInternalServerError)
		return
	}

	title := lectureID
	for _, mod := range outline.Modules {
		if mod.ID == moduleID {
			for _, lec := range mod.Lectures {
				if lec.ID == lectureID {
					title = lec.Title
				}
			}
		}
	}

	mdPath := filepath.Join(s.root, moduleID, "notes", lectureID+".md")
	md, err := os.ReadFile(mdPath)
	if err != nil {
		http.Error(w, "lecture not found", http.StatusNotFound)
		return
	}

	writeJSON(w, Lecture{ID: lectureID, Title: title, Markdown: string(md)})
}

// HandleQuiz serves a module's quiz (GET /api/modules/{moduleId}/quiz).
func (s *Service) HandleQuiz(w http.ResponseWriter, r *http.Request) {
	moduleID := r.PathValue("moduleId")
	quizPath := filepath.Join(s.root, moduleID, "quiz.json")

	data, err := os.ReadFile(quizPath)
	if err != nil {
		http.Error(w, "quiz not found", http.StatusNotFound)
		return
	}

	// Return the quiz as-is (the quiz.json file is already in the right format)
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(data)
}

// HandleLab serves lab instructions (GET /api/modules/{moduleId}/labs/{labId}).
// It also ensures the learner's lab working directory is seeded with starter
// files (and hidden grading scripts) the first time the lab is opened.
func (s *Service) HandleLab(w http.ResponseWriter, r *http.Request) {
	moduleID := r.PathValue("moduleId")
	labID := r.PathValue("labId")

	// Find the lab title from outline
	outline, err := s.loadOutline()
	if err == nil {
		for _, mod := range outline.Modules {
			if mod.ID == moduleID {
				for _, lab := range mod.Labs {
					if lab.ID == labID {
						if s.seeder != nil {
							if _, err := s.seeder.Ensure(moduleID, labID); err != nil {
								http.Error(w, "failed to set up lab workspace: "+err.Error(), http.StatusInternalServerError)
								return
							}
						}
						mdPath := filepath.Join(s.root, moduleID, labID, "lab.md")
						md, err := os.ReadFile(mdPath)
						if err != nil {
							http.Error(w, "lab not found", http.StatusNotFound)
							return
						}
						writeJSON(w, LabInstructions{ID: labID, Title: lab.Title, Markdown: string(md)})
						return
					}
				}
			}
		}
	}

	http.Error(w, "lab not found", http.StatusNotFound)
}

// loadOutline reads and parses outline.json from the content root.
func (s *Service) loadOutline() (*Outline, error) {
	data, err := os.ReadFile(filepath.Join(s.root, "outline.json"))
	if err != nil {
		return nil, err
	}
	var outline Outline
	if err := json.Unmarshal(data, &outline); err != nil {
		return nil, err
	}
	return &outline, nil
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
