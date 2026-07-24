// Package grade runs lab validation scripts (check.sh) and records results.
//
// When the learner clicks "Check" in the UI, the backend executes the lab's
// check.sh inside the lab working directory. The check.sh script runs real
// terraform/juju commands, evaluates assertions, and emits a JSON result.
// The backend parses this and records progress (keyed by course_id).
package grade

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/juju-tf-course/platform/backend/internal/content"
	"github.com/juju-tf-course/platform/backend/internal/store"
)

// Service handles lab grading.
type Service struct {
	labRoot    string
	contentSvc *content.Service
	store      *store.Store
}

// NewService creates a grading service.
func NewService(labRoot string, contentSvc *content.Service, s *store.Store) *Service {
	return &Service{labRoot: labRoot, contentSvc: contentSvc, store: s}
}

// GradeResult is the JSON output expected from check.sh.
type GradeResult struct {
	LabID  string       `json:"labId"`
	Passed bool         `json:"passed"`
	Tasks  []TaskResult `json:"tasks"`
}

// TaskResult is the result of a single lab task.
type TaskResult struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Passed  bool   `json:"passed"`
	Message string `json:"message"`
}

// HandleCheck executes a lab's check.sh and returns the grade.
// POST /api/courses/{courseId}/modules/{moduleId}/labs/{labId}/check
func (s *Service) HandleCheck(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	moduleID := r.PathValue("moduleId")
	labID := r.PathValue("labId")

	// The lab working directory is <lab-root>/<labId>
	labDir := filepath.Join(s.labRoot, labID)
	if _, err := os.Stat(labDir); err != nil {
		http.Error(w, "lab directory not found", http.StatusNotFound)
		return
	}

	// Find check.sh — it may be in the lab dir or in the content repo
	checkPath := filepath.Join(labDir, "check.sh")
	if _, err := os.Stat(checkPath); err != nil {
		// Fallback: look in the course's content directory
		if contentPath, ok := s.contentSvc.ContentPathFor(courseID); ok {
			checkPath = filepath.Join(contentPath, moduleID, labID, "check.sh")
		}
		if _, err := os.Stat(checkPath); err != nil {
			http.Error(w, "check.sh not found", http.StatusNotFound)
			return
		}
	}

	// Execute check.sh
	cmd := exec.CommandContext(r.Context(), "bash", checkPath)
	cmd.Dir = labDir
	output, _ := cmd.CombinedOutput() // ignore exit code — parse JSON anyway

	// Parse JSON result from stdout
	result := parseGradeOutput(string(output), labID)

	// Record progress (keyed by course_id)
	if result.Passed {
		_ = s.store.RecordLab(courseID, moduleID, labID)
	}

	writeJSON(w, result)
}

// parseGradeOutput extracts the GradeResult JSON from check.sh output.
func parseGradeOutput(output string, labID string) GradeResult {
	result := GradeResult{
		LabID:  labID,
		Passed: false,
		Tasks:  []TaskResult{},
	}

	lines := strings.Split(output, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if !strings.HasPrefix(line, "{") {
			continue
		}

		// Try as bare GradeResult
		var gr GradeResult
		if err := json.Unmarshal([]byte(line), &gr); err == nil && gr.Tasks != nil {
			gr.LabID = labID
			return gr
		}

		// Try as {"gradeResult": {...}}
		var wrapper struct {
			GradeResult GradeResult `json:"gradeResult"`
		}
		if err := json.Unmarshal([]byte(line), &wrapper); err == nil {
			wrapper.GradeResult.LabID = labID
			if wrapper.GradeResult.Tasks == nil {
				wrapper.GradeResult.Tasks = []TaskResult{}
			}
			return wrapper.GradeResult
		}
	}

	// No JSON found — treat as failed
	result.Tasks = []TaskResult{
		{
			ID:      "default",
			Name:    "Lab check",
			Passed:  false,
			Message: fmt.Sprintf("check.sh did not produce valid JSON output. Output:\n%s", output),
		},
	}
	return result
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
