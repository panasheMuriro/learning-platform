// Package quiz evaluates quiz answers and records scores.
//
// Quiz definitions are read from the course's content directory (resolved via
// the content service), and results are recorded in the Postgres store keyed
// by course_id + module_id.
package quiz

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"

	"github.com/juju-tf-course/platform/backend/internal/content"
	"github.com/juju-tf-course/platform/backend/internal/store"
)

// Scorer evaluates quiz submissions.
type Scorer struct {
	contentSvc *content.Service
	store      *store.Store
}

// NewScorer creates a new quiz scorer.
func NewScorer(contentSvc *content.Service, s *store.Store) *Scorer {
	return &Scorer{contentSvc: contentSvc, store: s}
}

// Question is an alias for the shared content question type.
type Question = content.Question

// Quiz is a module quiz.
type Quiz struct {
	ModuleID  string     `json:"moduleId"`
	Questions []Question `json:"questions"`
}

// SubmitRequest is the body for POST /api/courses/{courseId}/modules/{moduleId}/quiz/submit.
type SubmitRequest struct {
	Answers map[string]any `json:"answers"` // questionID -> answer
}

// SubmitResponse is the result of a quiz submission.
type SubmitResponse struct {
	Score  int  `json:"score"`  // percentage 0-100
	Passed bool `json:"passed"` // true if score >= 70
}

// HandleSubmit scores a quiz submission.
// POST /api/courses/{courseId}/modules/{moduleId}/quiz/submit
func (s *Scorer) HandleSubmit(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	moduleID := r.PathValue("moduleId")

	// Resolve the course's content directory
	contentPath, ok := s.contentSvc.ContentPathFor(courseID)
	if !ok {
		http.Error(w, "course not found", http.StatusNotFound)
		return
	}

	// Load quiz definition
	quizPath := filepath.Join(contentPath, moduleID, "quiz.json")
	data, err := os.ReadFile(quizPath)
	if err != nil {
		http.Error(w, "quiz not found", http.StatusNotFound)
		return
	}

	var quiz Quiz
	if err := json.Unmarshal(data, &quiz); err != nil {
		http.Error(w, "invalid quiz format", http.StatusInternalServerError)
		return
	}

	// Parse submission
	var req SubmitRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	score, passed := scoreSubmission(quiz.Questions, req)

	// Record progress (keyed by course_id)
	_ = s.store.RecordQuiz(courseID, moduleID, score, passed)

	writeJSON(w, SubmitResponse{Score: score, Passed: passed})
}

// HandleSubmitLecture scores a mini-quiz attached to a lecture.
// POST /api/courses/{courseId}/modules/{moduleId}/lectures/{lectureId}/quiz/submit
func (s *Scorer) HandleSubmitLecture(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	moduleID := r.PathValue("moduleId")
	lectureID := r.PathValue("lectureId")

	contentPath, ok := s.contentSvc.ContentPathFor(courseID)
	if !ok {
		http.Error(w, "course not found", http.StatusNotFound)
		return
	}

	quizPath := filepath.Join(contentPath, moduleID, "notes", lectureID+".quiz.json")
	data, err := os.ReadFile(quizPath)
	if err != nil {
		http.Error(w, "lecture quiz not found", http.StatusNotFound)
		return
	}

	var payload struct {
		Questions []Question `json:"questions"`
	}
	if err := json.Unmarshal(data, &payload); err != nil {
		http.Error(w, "invalid lecture quiz format", http.StatusInternalServerError)
		return
	}

	var req SubmitRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	score, passed := scoreSubmission(payload.Questions, req)
	writeJSON(w, SubmitResponse{Score: score, Passed: passed})
}

// scoreSubmission calculates a percentage score and pass/fail for a set of questions.
func scoreSubmission(questions []Question, req SubmitRequest) (int, bool) {
	correct := 0
	for _, q := range questions {
		userAns, ok := req.Answers[q.ID]
		if !ok {
			continue
		}
		if answersMatch(q.Answer, userAns) {
			correct++
		}
	}

	total := len(questions)
	score := 0
	if total > 0 {
		score = (correct * 100) / total
	}
	passed := score >= 70
	return score, passed
}

// answersMatch checks if the user's answer matches the correct answer.
// Handles both string and []string answers.
func answersMatch(correct any, user any) bool {
	switch ca := correct.(type) {
	case string:
		ua, ok := user.(string)
		return ok && ua == ca
	case []any:
		ua, ok := user.([]any)
		if !ok {
			return false
		}
		if len(ca) != len(ua) {
			return false
		}
		correctSet := make(map[string]bool)
		for _, c := range ca {
			if s, ok := c.(string); ok {
				correctSet[s] = true
			}
		}
		for _, u := range ua {
			if s, ok := u.(string); ok {
				if !correctSet[s] {
					return false
				}
			}
		}
		return true
	case []string:
		ua, ok := user.([]any)
		if !ok {
			return false
		}
		if len(ca) != len(ua) {
			return false
		}
		correctSet := make(map[string]bool)
		for _, c := range ca {
			correctSet[c] = true
		}
		for _, u := range ua {
			if s, ok := u.(string); ok {
				if !correctSet[s] {
					return false
				}
			}
		}
		return true
	default:
		return false
	}
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
