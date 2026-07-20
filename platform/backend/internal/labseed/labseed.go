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
// Only the starter files are meant for the learner to see and edit; the
// .grading directory is hidden from the code-server file explorer via
// .vscode/settings.json so it doesn't confuse learners who are focused on
// Terraform, not on how the course itself is graded.
package labseed

import (
	"os"
	"path/filepath"
)

// Service seeds lab working directories from the course content directory.
type Service struct {
	contentDir string
	labRoot    string
}

// NewService creates a lab seeding service.
func NewService(contentDir, labRoot string) *Service {
	return &Service{contentDir: contentDir, labRoot: labRoot}
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
// lab's starter files and (hidden) grading scripts. It's idempotent and safe
// to call every time a lab is opened or checked — starter files are never
// overwritten once they exist, but the grading scripts are always refreshed
// to the latest version from the content directory.
func (s *Service) Ensure(moduleID, labID string) (labDir string, err error) {
	labDir = filepath.Join(s.labRoot, labID)
	labContentDir := filepath.Join(s.contentDir, moduleID, labID)

	if err := os.MkdirAll(labDir, 0o755); err != nil {
		return "", err
	}

	// Copy starter files, without overwriting anything the learner already
	// has (so re-opening a lab never clobbers their work).
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
			_ = os.WriteFile(dst, data, 0o644)
		}
	}

	// Seed (and keep up to date) the hidden grading scripts.
	gradingDir := filepath.Join(labDir, ".grading")
	if err := os.MkdirAll(gradingDir, 0o755); err != nil {
		return "", err
	}
	for _, name := range []string{"check.sh", "setup.sh"} {
		src := filepath.Join(labContentDir, name)
		if data, err := os.ReadFile(src); err == nil {
			_ = os.WriteFile(filepath.Join(gradingDir, name), data, 0o755)
		}
	}
	if data, err := os.ReadFile(filepath.Join(s.contentDir, "shared", "check-helper.sh")); err == nil {
		_ = os.WriteFile(filepath.Join(gradingDir, "check-helper.sh"), data, 0o755)
	}

	// Hide .grading (and .vscode itself) from the code-server file explorer.
	vscodeDir := filepath.Join(labDir, ".vscode")
	if err := os.MkdirAll(vscodeDir, 0o755); err != nil {
		return "", err
	}
	settingsPath := filepath.Join(vscodeDir, "settings.json")
	if _, err := os.Stat(settingsPath); err != nil {
		_ = os.WriteFile(settingsPath, []byte(hiddenSettings), 0o644)
	}

	return labDir, nil
}

// GradingScriptPath returns the path to check.sh inside a lab's hidden
// .grading directory (whether or not it's been seeded yet — callers should
// use Ensure first).
func (s *Service) GradingScriptPath(labID string) string {
	return filepath.Join(s.labRoot, labID, ".grading", "check.sh")
}
