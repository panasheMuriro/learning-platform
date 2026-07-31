// Package files provides a file API for the in-browser lab workspace.
//
// It allows the frontend to list, read, and write files within the learner's
// lab working directory. Path traversal is prevented by resolving and checking
// that all paths stay within the configured lab root.
package files

import (
	"encoding/json"
	"io"
	"io/fs"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

// API provides file operations scoped to a root directory.
type API struct {
	root string
}

// NewAPI creates a file API rooted at the given directory.
func NewAPI(root string) *API {
	return &API{root: root}
}

// FileEntry represents a file or directory in the file tree.
type FileEntry struct {
	Name        string `json:"name"`
	Path        string `json:"path"`
	IsDirectory bool   `json:"isDirectory"`
}

// HandleList lists files in a directory (GET /api/files?path=...).
func (a *API) HandleList(w http.ResponseWriter, r *http.Request) {
	relPath := r.URL.Query().Get("path")
	fullPath, err := a.safePath(relPath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	entries, err := os.ReadDir(fullPath)
	if err != nil {
		http.Error(w, "failed to list directory", http.StatusInternalServerError)
		return
	}

	var files []FileEntry
	for _, entry := range entries {
		info, err := entry.Info()
		if err != nil {
			continue
		}
		files = append(files, FileEntry{
			Name:        entry.Name(),
			Path:        filepath.Join(relPath, entry.Name()),
			IsDirectory: info.IsDir(),
		})
	}

	writeJSON(w, files)
}

// HandleRead reads a file's content (GET /api/files/content?path=...).
func (a *API) HandleRead(w http.ResponseWriter, r *http.Request) {
	relPath := r.URL.Query().Get("path")
	fullPath, err := a.safePath(relPath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	data, err := os.ReadFile(fullPath)
	if err != nil {
		http.Error(w, "file not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	_, _ = w.Write(data)
}

// HandleWrite writes content to a file (PUT /api/files/content?path=...).
func (a *API) HandleWrite(w http.ResponseWriter, r *http.Request) {
	relPath := r.URL.Query().Get("path")
	fullPath, err := a.safePath(relPath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	data, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "failed to read request body", http.StatusBadRequest)
		return
	}

	if err := os.WriteFile(fullPath, data, 0o666); err != nil {
		http.Error(w, "failed to write file", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// safePath resolves a relative path against the root and ensures it does not
// escape the root directory (path traversal protection).
func (a *API) safePath(relPath string) (string, error) {
	// Clean the path and remove any leading /
	cleaned := filepath.Clean("/" + relPath)
	if cleaned == "/" || cleaned == "." {
		return a.root, nil
	}
	cleaned = strings.TrimPrefix(cleaned, "/")

	fullPath := filepath.Join(a.root, cleaned)

	// Resolve symlinks and verify the result is within root
	resolved, err := filepath.EvalSymlinks(fullPath)
	if err != nil {
		// File may not exist yet (for writes) — check the parent
		parentResolved, perr := filepath.EvalSymlinks(filepath.Dir(fullPath))
		if perr != nil {
			return "", &fs.PathError{Op: "eval", Path: relPath, Err: fs.ErrNotExist}
		}
		if !isWithinRoot(parentResolved, a.root) {
			return "", &fs.PathError{Op: "eval", Path: relPath, Err: fs.ErrPermission}
		}
		return filepath.Join(parentResolved, filepath.Base(fullPath)), nil
	}

	if !isWithinRoot(resolved, a.root) {
		return "", &fs.PathError{Op: "eval", Path: relPath, Err: fs.ErrPermission}
	}

	return resolved, nil
}

// isWithinRoot checks if a path is within the root directory.
func isWithinRoot(path, root string) bool {
	absRoot, _ := filepath.Abs(root)
	absPath, _ := filepath.Abs(path)
	return strings.HasPrefix(absPath, absRoot)
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
