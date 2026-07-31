// Package labseed provisions a learner's lab working directory the first
// time a lab is opened or checked.
//
// A seeded lab directory looks like:
//
//	<lab-root>/<labId>/
//	  main.tf, variables.tf, ...   # starter files the learner edits
//	  .vscode/settings.json        # hides .grading/ from the code-server Explorer
//	  .grading/
//	    check.sh                   # grading script (backend-only, not for the learner)
//	    check-helper.sh            # shared helper sourced by check.sh
//	    setup.sh                   # one-time environment setup (if the lab has one)
//
// The content directory is resolved per-course via the content service.
package labseed

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"

	"github.com/juju-tf-course/platform/backend/internal/content"
)

// Service seeds lab working directories from the course content directory.
type Service struct {
	labRoot    string
	contentSvc *content.Service
}

// NewService creates a lab seeding service.
func NewService(labRoot string, contentSvc *content.Service) *Service {
	return &Service{labRoot: labRoot, contentSvc: contentSvc}
}

// hiddenSettings is written to <lab>/.vscode/settings.json so the code-server
// Explorer hides the grading scripts and its own .vscode folder.
const hiddenSettings = `{
  "files.exclude": {
    ".grading": true,
    ".vscode": true
  }
}
`

// Ensure makes sure the lab working directory exists and is seeded with the
// lab's starter files and (hidden) grading scripts. It's idempotent.
//
// The course's content directory is resolved via the content service so labs
// from any registered course can be seeded.
func (s *Service) Ensure(courseID, moduleID, labID string) (labDir string, err error) {
	labDir = filepath.Join(s.labRoot, labID)

	contentPath, ok := s.contentSvc.ContentPathFor(courseID)
	if !ok {
		return "", &os.PathError{Op: "resolve", Path: labID, Err: os.ErrNotExist}
	}
	labContentDir := filepath.Join(contentPath, moduleID, labID)

	if err := os.MkdirAll(labDir, 0o777); err != nil {
		return "", err
	}

	// Copy starter files, without overwriting anything the learner already has.
	starterDir := filepath.Join(labContentDir, "starter")
	if entries, err := os.ReadDir(starterDir); err == nil {
		for _, entry := range entries {
			if entry.IsDir() {
				continue
			}
			dst := filepath.Join(labDir, entry.Name())
			if _, err := os.Stat(dst); err == nil {
				continue // learner's file already exists — don't overwrite
			}
			data, err := os.ReadFile(filepath.Join(starterDir, entry.Name()))
			if err != nil {
				continue
			}
			_ = os.WriteFile(dst, data, 0o666)
		}
	}

	// Seed (and keep up to date) the hidden grading scripts.
	gradingDir := filepath.Join(labDir, ".grading")
	if err := os.MkdirAll(gradingDir, 0o777); err != nil {
		return "", err
	}
	for _, name := range []string{"check.sh", "setup.sh"} {
		src := filepath.Join(labContentDir, name)
		if data, err := os.ReadFile(src); err == nil {
			_ = os.WriteFile(filepath.Join(gradingDir, name), data, 0o755)
		}
	}
	// Shared helper lives at the course content root under shared/.
	if data, err := os.ReadFile(filepath.Join(contentPath, "shared", "check-helper.sh")); err == nil {
		_ = os.WriteFile(filepath.Join(gradingDir, "check-helper.sh"), data, 0o755)
	}

	// Hide .grading (and .vscode itself) from the code-server file explorer.
	vscodeDir := filepath.Join(labDir, ".vscode")
	if err := os.MkdirAll(vscodeDir, 0o777); err != nil {
		return "", err
	}
	settingsPath := filepath.Join(vscodeDir, "settings.json")
	if _, err := os.Stat(settingsPath); err != nil {
		_ = os.WriteFile(settingsPath, []byte(hiddenSettings), 0o666)
	}

	return labDir, nil
}

// GradingScriptPath returns the path to check.sh inside a lab's hidden
// .grading directory.
func (s *Service) GradingScriptPath(labID string) string {
	return filepath.Join(s.labRoot, labID, ".grading", "check.sh")
}

// HandleOpen seeds a lab working directory and returns the lab path.
// POST /api/courses/{courseId}/modules/{moduleId}/labs/{labId}/open
func (s *Service) HandleOpen(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	moduleID := r.PathValue("moduleId")
	labID := r.PathValue("labId")

	labDir, err := s.Ensure(courseID, moduleID, labID)
	if err != nil {
		http.Error(w, "failed to seed lab: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Return the lab path relative to the lab root so the file API (which
	// resolves paths relative to the same root) can access it correctly.
	relPath, err := filepath.Rel(s.labRoot, labDir)
	if err != nil {
		relPath = labID
	}

	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write([]byte(`{"labPath":"` + relPath + `"}`))
}

// ApplyWorkspace writes the file contents defined by a task's workspace into
// the lab directory. Existing files are overwritten so the workspace matches
// the currently selected task.
func (s *Service) ApplyWorkspace(courseID, moduleID, labID, taskID string) error {
	contentPath, ok := s.contentSvc.ContentPathFor(courseID)
	if !ok {
		return &os.PathError{Op: "resolve", Path: labID, Err: os.ErrNotExist}
	}

	tasksPath := filepath.Join(contentPath, moduleID, labID, "tasks.json")
	data, err := os.ReadFile(tasksPath)
	if err != nil {
		return nil // no tasks.json — nothing to apply
	}

	var payload struct {
		Tasks []struct {
			ID        string            `json:"id"`
			Workspace map[string]string `json:"workspace,omitempty"`
		} `json:"tasks"`
	}
	if err := json.Unmarshal(data, &payload); err != nil {
		return err
	}

	var workspace map[string]string
	for _, t := range payload.Tasks {
		if t.ID == taskID {
			workspace = t.Workspace
			break
		}
	}
	if len(workspace) == 0 {
		return nil
	}

	labDir := filepath.Join(s.labRoot, labID)
	if err := os.MkdirAll(labDir, 0o777); err != nil {
		return err
	}
	for relPath, content := range workspace {
		fullPath := filepath.Join(labDir, relPath)
		if err := os.MkdirAll(filepath.Dir(fullPath), 0o777); err != nil {
			return err
		}
		if err := os.WriteFile(fullPath, []byte(content), 0o666); err != nil {
			return err
		}
	}
	return nil
}

// HandleWorkspace applies a task's workspace files.
// POST /api/courses/{courseId}/modules/{moduleId}/labs/{labId}/tasks/{taskId}/workspace
func (s *Service) HandleWorkspace(w http.ResponseWriter, r *http.Request) {
	courseID := r.PathValue("courseId")
	moduleID := r.PathValue("moduleId")
	labID := r.PathValue("labId")
	taskID := r.PathValue("taskId")

	if err := s.ApplyWorkspace(courseID, moduleID, labID, taskID); err != nil {
		http.Error(w, "failed to apply workspace: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write([]byte(`{"ok":true}`))
}
