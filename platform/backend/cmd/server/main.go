// Package main is the entrypoint for the course platform backend.
//
// The backend is a single Go binary that serves:
//   - REST API: course catalog, content, quiz scoring, file API, grading, progress
//   - WebSocket: PTY terminal streaming for the in-browser terminal
//
// Everything runs locally. No auth — single local profile. Progress is stored
// in Postgres, keyed by course_id + module_id + lab_id.
package main

import (
	"context"
	"flag"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/juju-tf-course/platform/backend/internal/content"
	"github.com/juju-tf-course/platform/backend/internal/files"
	"github.com/juju-tf-course/platform/backend/internal/grade"
	"github.com/juju-tf-course/platform/backend/internal/labseed"
	"github.com/juju-tf-course/platform/backend/internal/pty"
	"github.com/juju-tf-course/platform/backend/internal/quiz"
	"github.com/juju-tf-course/platform/backend/internal/registry"
	"github.com/juju-tf-course/platform/backend/internal/store"
)

func main() {
	addr := flag.String("addr", ":8080", "listen address")
	contentRoot := flag.String("content-root", "../../content", "path to content root (parent of courses/)")
	labRoot := flag.String("lab-root", "/home/student", "root directory for lab workspaces")
	dbDSN := flag.String("db-dsn", "", "Postgres DSN (default: $DATABASE_URL or $DB_DSN or postgres://course:course@localhost:5432/course?sslmode=disable)")
	flag.Parse()

	// Resolve DSN
	dsn := *dbDSN
	if dsn == "" {
		dsn = store.DefaultDSN()
	}

	// Initialize Postgres store + auto-migrate
	st, err := store.Open(dsn)
	if err != nil {
		log.Fatalf("failed to open progress db: %v", err)
	}
	defer st.Close()

	host, port := store.ParseDSNHostPort(dsn)
	log.Printf("connected to postgres at %s:%s", host, port)

	// Initialize registry: scan content/courses/*/course.json and upsert into DB
	reg := registry.New(*contentRoot, st)
	if err := reg.Scan(); err != nil {
		log.Printf("warning: course registry scan failed: %v", err)
	}

	// Initialize services
	contentSvc := content.NewService(reg)
	quizSvc := quiz.NewScorer(contentSvc, st)
	fileAPI := files.NewAPI(*labRoot)
	gradeSvc := grade.NewService(*labRoot, contentSvc, st)
	seedSvc := labseed.NewService(*labRoot, contentSvc)
	ptySvc := pty.NewService(*labRoot)

	mux := http.NewServeMux()

	// Course catalog
	mux.HandleFunc("GET /api/courses", reg.HandleListCourses)

	// Content routes (course-scoped)
	mux.HandleFunc("GET /api/courses/{courseId}/outline", contentSvc.HandleOutline)
	mux.HandleFunc("GET /api/courses/{courseId}/modules/{moduleId}/lectures/{lectureId}", contentSvc.HandleLecture)
	mux.HandleFunc("GET /api/courses/{courseId}/modules/{moduleId}/quiz", contentSvc.HandleQuiz)
	mux.HandleFunc("GET /api/courses/{courseId}/modules/{moduleId}/labs/{labId}", contentSvc.HandleLab)

	// Quiz scoring (course-scoped)
	mux.HandleFunc("POST /api/courses/{courseId}/modules/{moduleId}/quiz/submit", quizSvc.HandleSubmit)

	// Grading (course-scoped)
	mux.HandleFunc("POST /api/courses/{courseId}/modules/{moduleId}/labs/{labId}/check", gradeSvc.HandleCheck)
	mux.HandleFunc("POST /api/courses/{courseId}/modules/{moduleId}/labs/{labId}/tasks/{taskId}/check", gradeSvc.HandleCheckTask)

	// Lab seeding (course-scoped) — seeds starter files into the lab workspace
	mux.HandleFunc("POST /api/courses/{courseId}/modules/{moduleId}/labs/{labId}/open", seedSvc.HandleOpen)

	// Progress (course-scoped)
	mux.HandleFunc("GET /api/courses/{courseId}/progress", st.HandleGetProgress)
	mux.HandleFunc("POST /api/courses/{courseId}/modules/{moduleId}/lectures/{lectureId}/complete", st.HandleMarkLectureComplete)
	mux.HandleFunc("DELETE /api/courses/{courseId}/modules/{moduleId}/lectures/{lectureId}/complete", st.HandleUnmarkLecture)
	mux.HandleFunc("DELETE /api/courses/{courseId}/modules/{moduleId}/labs/{labId}/complete", st.HandleUnmarkLab)
	mux.HandleFunc("DELETE /api/courses/{courseId}/modules/{moduleId}/quiz/complete", st.HandleUnmarkQuiz)

	// File API (course-agnostic — operates on lab-root)
	mux.HandleFunc("GET /api/files", fileAPI.HandleList)
	mux.HandleFunc("GET /api/files/content", fileAPI.HandleRead)
	mux.HandleFunc("PUT /api/files/content", fileAPI.HandleWrite)

	// WebSocket terminal (course-agnostic)
	mux.HandleFunc("GET /ws/terminal", ptySvc.HandleTerminal)

	// CORS for local dev (frontend on :3000, backend on :8080)
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

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Printf("shutdown error: %v", err)
	}
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
