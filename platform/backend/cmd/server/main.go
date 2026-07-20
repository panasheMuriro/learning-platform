// Package main is the entrypoint for the Juju+Terraform course backend.
//
// The backend is a single Go binary that serves:
//   - REST API: content, quiz scoring, file API, grading, progress
//   - WebSocket: PTY terminal streaming for the in-browser terminal
//
// Everything runs locally inside the Workshop container alongside the
// learner's lab environment. No auth, no multi-tenant — single local profile.
package main

import (
	"context"
	"flag"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/juju-tf-course/platform/backend/internal/content"
	"github.com/juju-tf-course/platform/backend/internal/files"
	"github.com/juju-tf-course/platform/backend/internal/grade"
	"github.com/juju-tf-course/platform/backend/internal/labseed"
	"github.com/juju-tf-course/platform/backend/internal/progress"
	"github.com/juju-tf-course/platform/backend/internal/pty"
	"github.com/juju-tf-course/platform/backend/internal/quiz"
)

func main() {
	addr := flag.String("addr", ":8080", "listen address")
	contentDir := flag.String("content", "../../content", "path to content directory")
	labRoot := flag.String("lab-root", "/home/student", "root directory for lab workspaces")
	dbPath := flag.String("db", "course.db", "path to SQLite progress database")
	frontendDir := flag.String("frontend", "", "path to built frontend (dist/). If set, serves the SPA on the same port as the API.")
	codeServerURL := flag.String("code-server-url", "", "internal URL of code-server (e.g. http://localhost:8081). If set, proxies /code-server/ to it so only one port needs to be exposed.")
	flag.Parse()

	// Initialize progress store (SQLite)
	store, err := progress.Open(*dbPath)
	if err != nil {
		log.Fatalf("failed to open progress db: %v", err)
	}
	defer store.Close()

	// Initialize services
	seeder := labseed.NewService(*contentDir, *labRoot)
	contentSvc := content.NewService(*contentDir, seeder)
	quizSvc := quiz.NewScorer()
	fileAPI := files.NewAPI(*labRoot)
	gradeSvc := grade.NewService(*labRoot, store, seeder)
	ptySvc := pty.NewService(*labRoot)

	mux := http.NewServeMux()

	// Content routes
	mux.HandleFunc("GET /api/outline", contentSvc.HandleOutline)
	mux.HandleFunc("GET /api/modules/{moduleId}/lectures/{lectureId}", contentSvc.HandleLecture)
	mux.HandleFunc("GET /api/modules/{moduleId}/quiz", contentSvc.HandleQuiz)
	mux.HandleFunc("GET /api/modules/{moduleId}/labs/{labId}", contentSvc.HandleLab)

	// Quiz scoring
	mux.HandleFunc("POST /api/modules/{moduleId}/quiz/submit", quizSvc.HandleSubmit(contentSvc, store))

	// File API (for lab workspace editor + file tree)
	mux.HandleFunc("GET /api/files", fileAPI.HandleList)
	mux.HandleFunc("GET /api/files/content", fileAPI.HandleRead)
	mux.HandleFunc("PUT /api/files/content", fileAPI.HandleWrite)

	// Grading
	mux.HandleFunc("POST /api/modules/{moduleId}/labs/{labId}/check", gradeSvc.HandleCheck)

	// Progress
	mux.HandleFunc("GET /api/progress", store.HandleGetProgress)

	// WebSocket terminal
	mux.HandleFunc("GET /ws/terminal", ptySvc.HandleTerminal)

	// Reverse-proxy code-server so it's reachable through this same port at
	// /code-server/ — avoids needing a second exposed port/tunnel.
	if *codeServerURL != "" {
		target, err := url.Parse(*codeServerURL)
		if err != nil {
			log.Fatalf("invalid --code-server-url %q: %v", *codeServerURL, err)
		}
		proxy := httputil.NewSingleHostReverseProxy(target)
		codeServerHandler := http.StripPrefix("/code-server", withPathRewrite(proxy))
		for _, method := range []string{"GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"} {
			mux.Handle(method+" /code-server/", codeServerHandler)
		}
	}

	// Serve built frontend (SPA) if --frontend is set.
	// In production, the backend serves everything on one port — no Vite dev server.
	if *frontendDir != "" {
		fs := http.FileServer(http.Dir(*frontendDir))
		mux.Handle("GET /", spaHandler{fs: fs, root: *frontendDir})
	}

	// CORS for local dev (frontend on :3000, backend on :8080)
	// In production (single port), CORS is unnecessary but harmless.
	handler := corsMiddleware(mux)

	srv := &http.Server{
		Addr:              *addr,
		Handler:           handler,
		ReadHeaderTimeout: 10 * time.Second,
	}

	// Graceful shutdown
	go func() {
		log.Printf("backend listening on %s", *addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server error: %v", err)
		}
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop
	log.Println("shutting down...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Printf("shutdown error: %v", err)
	}
}

// withPathRewrite ensures requests forwarded to code-server carry an empty
// path instead of "" when the stripped prefix leaves nothing (i.e. a request
// to exactly /code-server should reach code-server's "/").
func withPathRewrite(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/") {
			r.URL.Path = "/" + r.URL.Path
		}
		next.ServeHTTP(w, r)
	})
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// spaHandler serves static files from a directory, falling back to index.html
// for any path that doesn't match a file. This enables client-side routing
// (e.g., /modules/module-01/lectures/01-what-is-juju) to work in production.
type spaHandler struct {
	fs   http.Handler
	root string
}

func (h spaHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Check if the requested file exists
	path := r.URL.Path
	if path == "/" {
		path = "/index.html"
	}
	fullPath := h.root + path
	if info, err := os.Stat(fullPath); err == nil && !info.IsDir() {
		h.fs.ServeHTTP(w, r)
		return
	}
	// Fallback to index.html for SPA routing
	r.URL.Path = "/"
	h.fs.ServeHTTP(w, r)
}
