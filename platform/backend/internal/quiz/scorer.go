// Package quiz evaluates quiz answers and records scores.
package quiz

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"

	"github.com/juju-tf-course/platform/backend/internal/content"
	"github.com/juju-tf-course/platform/backend/internal/progress"
)

// Scorer evaluates quiz submissions.
type Scorer struct{}

// NewScorer creates a new quiz scorer.
func NewScorer() *Scorer {
	return &Scorer{}
}

// Question represents a single quiz question (matches content/quiz.json format).
type Question struct {
	ID          string   `json:"id"`
	Prompt      string   `json:"prompt"`
	Type        string   `json:"type"` // "single-choice", "multi-choice", "text-answer"
	Options     []string `json:"options,omitempty"`
	Answer      any      `json:"answer"` // string or []string
	Explanation string   `json:"explanation,omitempty"`
}

// Quiz is a module quiz.
type Quiz struct {
	ModuleID  string     `json:"moduleId"`
	Questions []Question `json:"questions"`
}

// SubmitRequest is the body for POST /api/modules/{moduleId}/quiz/submit.
type SubmitRequest struct {
	Answers map[string]any `json:"answers"` // questionID -> answer
}

// SubmitResponse is the result of a quiz submission.
type SubmitResponse struct {
	Score  int  `json:"score"`  // percentage 0-100
	Passed bool `json:"passed"` // true if score >= 70
}

// HandleSubmit returns an http.HandlerFunc that scores a quiz submission.
// It reads the quiz definition from the content service, evaluates answers,
// and records the result in the progress store.
func (s *Scorer) HandleSubmit(contentSvc *content.Service, store *progress.Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		moduleID := r.PathValue("moduleId")

		// Load quiz definition
		quizPath := filepath.Join(contentSvc.Root(), moduleID, "quiz.json")
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

		// Score
		correct := 0
		for _, q := range quiz.Questions {
			userAns, ok := req.Answers[q.ID]
			if !ok {
				continue
			}
			if answersMatch(q.Answer, userAns) {
				correct++
			}
		}

		total := len(quiz.Questions)
		score := 0
		if total > 0 {
			score = (correct * 100) / total
		}
		passed := score >= 70

		// Record progress
		_ = store.RecordQuiz(moduleID, score, passed)

		writeJSON(w, SubmitResponse{Score: score, Passed: passed})
	}
}

// answersMatch checks if the user's answer matches the correct answer.
// Handles both string and []string answers.
func answersMatch(correct any, user any) bool {
	// Normalize both to comparable forms
	switch ca := correct.(type) {
	case string:
		ua, ok := user.(string)
		return ok && ua == ca
	case []any:
		// Multi-choice: all correct answers must be present, no extras
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
