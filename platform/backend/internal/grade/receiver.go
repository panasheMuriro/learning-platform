// Package grade runs lab validation scripts (check.sh) and records results.
//
// When the learner clicks "Check" in the UI, the backend executes the lab's
// check.sh inside the lab working directory. The check.sh script runs real
// terraform/juju commands, evaluates assertions, and emits a JSON result.
// The backend parses this and records progress.
package grade

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/juju-tf-course/platform/backend/internal/labseed"
	"github.com/juju-tf-course/platform/backend/internal/progress"
)

// Service handles lab grading.
type Service struct {
	root   string
	store  *progress.Store
	seeder *labseed.Service
}

// NewService creates a grading service.
func NewService(root string, store *progress.Store, seeder *labseed.Service) *Service {
	return &Service{root: root, store: store, seeder: seeder}
}

// GradeResult is the JSON output expected from check.sh.
type GradeResult struct {
	LabID string     `json:"labId"`
	Passed bool      `json:"passed"`
	Tasks []TaskResult `json:"tasks"`
}

// TaskResult is the result of a single lab task.
type TaskResult struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Passed  bool   `json:"passed"`
	Message string `json:"message"`
}

// HandleCheck executes a lab's check.sh (from the hidden .grading directory)
// and returns the grade.
// POST /api/modules/{moduleId}/labs/{labId}/check
func (s *Service) HandleCheck(w http.ResponseWriter, r *http.Request) {
	moduleID := r.PathValue("moduleId")
	labID := r.PathValue("labId")

	// The lab working directory is /home/student/<labId>
	labDir := filepath.Join(s.root, labID)

	// Make sure the lab (and its hidden .grading scripts) are seeded —
	// covers labs checked before ever being opened, and keeps the grading
	// scripts up to date with the content repo.
	if s.seeder != nil {
		if _, err := s.seeder.Ensure(moduleID, labID); err != nil {
			http.Error(w, "failed to set up lab workspace: "+err.Error(), http.StatusInternalServerError)
			return
		}
	}

	if _, err := os.Stat(labDir); err != nil {
		http.Error(w, "lab directory not found", http.StatusNotFound)
		return
	}

	checkPath := filepath.Join(labDir, ".grading", "check.sh")
	if _, err := os.Stat(checkPath); err != nil {
		http.Error(w, "check.sh not found", http.StatusNotFound)
		return
	}

	// Execute check.sh with the lab dir (not .grading) as the working
	// directory, so its relative paths (main.tf, .terraform, etc.) resolve
	// against the learner's actual files.
	cmd := exec.CommandContext(r.Context(), "bash", checkPath)
	cmd.Dir = labDir
	output, err := cmd.CombinedOutput()
	if err != nil {
		// check.sh exited non-zero — try to parse JSON from output anyway
		// (it may have emitted a fail result before exiting)
	}

	// Parse JSON result from stdout
	// The check.sh should emit a JSON line starting with {"gradeResult":
	result := parseGradeOutput(string(output), labID)

	// Record progress
	if result.Passed {
		_ = s.store.RecordLab(moduleID, labID)
	}

	writeJSON(w, result)
}

// parseGradeOutput extracts the GradeResult JSON from check.sh output.
// The check.sh script emits a JSON object (possibly multi-line, pretty-printed
// by jq). This function finds the first '{' and tries to parse the JSON from
// there. It handles both bare GradeResult and {"gradeResult": {...}} wrapper.
func parseGradeOutput(output string, labID string) GradeResult {
	result := GradeResult{
		LabID:  labID,
		Passed: false,
		Tasks:  []TaskResult{},
	}

	// Find the first '{' in the output
	start := strings.Index(output, "{")
	if start < 0 {
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

	jsonStr := output[start:]

	// Try as bare GradeResult
	var gr GradeResult
	if err := json.Unmarshal([]byte(jsonStr), &gr); err == nil && gr.Tasks != nil {
		gr.LabID = labID
		if gr.Tasks == nil {
			gr.Tasks = []TaskResult{}
		}
		return gr
	}

	// Try as {"gradeResult": {...}}
	var wrapper struct {
		GradeResult GradeResult `json:"gradeResult"`
	}
	if err := json.Unmarshal([]byte(jsonStr), &wrapper); err == nil {
		wrapper.GradeResult.LabID = labID
		if wrapper.GradeResult.Tasks == nil {
			wrapper.GradeResult.Tasks = []TaskResult{}
		}
		return wrapper.GradeResult
	}

	// JSON found but couldn't parse — treat as failed
	result.Tasks = []TaskResult{
		{
			ID:      "default",
			Name:    "Lab check",
			Passed:  false,
			Message: fmt.Sprintf("check.sh produced invalid JSON. Output:\n%s", output),
		},
	}
	return result
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
