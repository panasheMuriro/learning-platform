// Package registry discovers courses on the filesystem and registers them in
// the database.
//
// At startup it scans <content-root>/courses/*/course.json, parses each, and
// upserts it into the courses table via the store (GORM). The content itself
// stays on the filesystem — the DB only stores metadata + a content_path
// pointer.
package registry

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"github.com/juju-tf-course/platform/backend/internal/store"
)

// Registry holds the content root and a reference to the store.
type Registry struct {
	contentRoot string
	store       *store.Store
}

// New creates a registry rooted at contentRoot (the parent of the courses/ dir).
func New(contentRoot string, s *store.Store) *Registry {
	return &Registry{contentRoot: contentRoot, store: s}
}

// CourseMeta is the shape of a course.json file on disk.
type CourseMeta struct {
	ID            string   `json:"id"`
	Slug          string   `json:"slug"`
	Title         string   `json:"title"`
	Summary       string   `json:"summary"`
	Icon          string   `json:"icon"`
	Version       string   `json:"version"`
	RequiredTools []string `json:"requiredTools"`
	License       string   `json:"license"`
	Workspace     string   `json:"workspace"` // "code-server" (default) or "terminal"
}

// Scan walks <content-root>/courses/*/course.json and upserts each course
// into the database. It logs (not fails) on individual course errors so one
// broken course.json doesn't prevent the rest from loading.
func (r *Registry) Scan() error {
	coursesDir := filepath.Join(r.contentRoot, "courses")
	entries, err := os.ReadDir(coursesDir)
	if err != nil {
		return fmt.Errorf("read courses dir %s: %w", coursesDir, err)
	}

	loaded := 0
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		slug := entry.Name()
		coursePath := filepath.Join(coursesDir, slug)
		metaPath := filepath.Join(coursePath, "course.json")

		data, err := os.ReadFile(metaPath)
		if err != nil {
			log.Printf("registry: skipping %s (no course.json: %v)", slug, err)
			continue
		}

		var meta CourseMeta
		if err := json.Unmarshal(data, &meta); err != nil {
			log.Printf("registry: skipping %s (invalid course.json: %v)", slug, err)
			continue
		}

		// Fall back to the directory slug if the file doesn't specify one.
		if meta.ID == "" {
			meta.ID = slug
		}
		if meta.Slug == "" {
			meta.Slug = slug
		}

		c := store.Course{
			ID:          meta.ID,
			Slug:        meta.Slug,
			Title:       meta.Title,
			Summary:     meta.Summary,
			Icon:        meta.Icon,
			Version:     meta.Version,
			ContentPath: coursePath,
			Enabled:     true,
			Workspace:   meta.Workspace,
		}
		if err := r.store.UpsertCourse(c); err != nil {
			log.Printf("registry: failed to upsert course %s: %v", slug, err)
			continue
		}
		loaded++
	}

	log.Printf("registry: loaded %d course(s) from %s", loaded, coursesDir)

	// Remove stale courses that exist in the DB but no longer have a
	// course.json on disk (e.g. a course directory was deleted).
	allCourses, err := r.store.ListAllCourses()
	if err != nil {
		log.Printf("registry: failed to list stale courses: %v", err)
		return nil
	}
	for _, c := range allCourses {
		metaPath := filepath.Join(coursesDir, c.Slug, "course.json")
		if _, err := os.Stat(metaPath); err != nil {
			log.Printf("registry: removing stale course %s (no longer on disk)", c.Slug)
			if err := r.store.DeleteCourse(c.ID); err != nil {
				log.Printf("registry: failed to delete stale course %s: %v", c.Slug, err)
			}
		}
	}

	return nil
}

// List returns all enabled courses (delegates to the store).
func (r *Registry) List() ([]store.Course, error) {
	return r.store.ListCourses()
}

// Get returns a single course by slug or id (delegates to the store).
func (r *Registry) Get(slugOrID string) (*store.Course, error) {
	return r.store.GetCourse(slugOrID)
}

// HandleListCourses is the HTTP handler for GET /api/courses.
func (r *Registry) HandleListCourses(w http.ResponseWriter, req *http.Request) {
	courses, err := r.List()
	if err != nil {
		http.Error(w, "failed to list courses", http.StatusInternalServerError)
		return
	}
	// Don't leak the filesystem content_path to the frontend.
	type courseDTO struct {
		ID        string `json:"id"`
		Slug      string `json:"slug"`
		Title     string `json:"title"`
		Summary   string `json:"summary"`
		Icon      string `json:"icon"`
		Version   string `json:"version"`
		Workspace string `json:"workspace"`
	}
	dtos := make([]courseDTO, 0, len(courses))
	for _, c := range courses {
		ws := c.Workspace
		if ws == "" {
			ws = "code-server"
		}
		dtos = append(dtos, courseDTO{
			ID:        c.ID,
			Slug:      c.Slug,
			Title:     c.Title,
			Summary:   c.Summary,
			Icon:      c.Icon,
			Version:   c.Version,
			Workspace: ws,
		})
	}
	writeJSON(w, dtos)
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
