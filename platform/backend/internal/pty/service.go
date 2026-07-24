// Package pty provides a WebSocket-based terminal that spawns a real shell
// via a pseudo-terminal (PTY). This powers the in-browser terminal in the
// lab workspace.
//
// Since the backend runs inside the same Workshop container as the learner's
// lab environment, the PTY is spawned directly — no SSH needed. The shell's
// working directory is set to the lab root.
package pty

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"sync"

	"github.com/creack/pty"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // local, no origin check needed
	},
}

// Service manages PTY terminal sessions over WebSocket.
type Service struct {
	root string
}

// NewService creates a PTY service rooted at the given directory.
func NewService(root string) *Service {
	return &Service{root: root}
}

// TerminalMessage is the JSON message format for the terminal WebSocket.
type TerminalMessage struct {
	Type string `json:"type"` // "input", "resize"
	Data string `json:"data,omitempty"`
	Cols int    `json:"cols,omitempty"`
	Rows int    `json:"rows,omitempty"`
}

// HandleTerminal upgrades to a WebSocket and streams a PTY shell.
// GET /ws/terminal
func (s *Service) HandleTerminal(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("ws upgrade error: %v", err)
		return
	}
	defer conn.Close()

	// Determine shell and working directory
	shell := os.Getenv("SHELL")
	if shell == "" {
		shell = "/bin/bash"
	}

	workDir := s.root
	// If a lab path was specified via query param, resolve it relative to the
	// lab root. The path is relative (e.g. "lab-01-first-model-app").
	if labPath := r.URL.Query().Get("path"); labPath != "" {
		fullPath := filepath.Join(s.root, filepath.Clean(labPath))
		if info, err := os.Stat(fullPath); err == nil && info.IsDir() {
			workDir = fullPath
		}
	}

	// Start the shell in a PTY
	cmd := exec.Command(shell, "-l")
	cmd.Dir = workDir
	cmd.Env = append(os.Environ(), "TERM=xterm-256color")

	ptmx, err := pty.Start(cmd)
	if err != nil {
		log.Printf("pty start error: %v", err)
		conn.WriteJSON(TerminalMessage{Type: "output", Data: "\r\nFailed to start terminal\r\n"})
		return
	}
	defer ptmx.Close()

	var wg sync.WaitGroup
	processDone := make(chan struct{})

	// PTY -> WebSocket: read shell output and send to browser
	wg.Add(1)
	go func() {
		defer wg.Done()
		buf := make([]byte, 4096)
		for {
			n, err := ptmx.Read(buf)
			if err != nil {
				close(processDone)
				return
			}
			if err := conn.WriteMessage(websocket.TextMessage, buf[:n]); err != nil {
				return
			}
		}
	}()

	// WebSocket -> PTY: read browser input and write to shell
	go func() {
		for {
			_, msg, err := conn.ReadMessage()
			if err != nil {
				_ = cmd.Process.Kill()
				return
			}

			var tm TerminalMessage
			if err := json.Unmarshal(msg, &tm); err != nil {
				// If not JSON, treat as raw input
				_, _ = ptmx.Write(msg)
				continue
			}

			switch tm.Type {
			case "input":
				_, _ = ptmx.Write([]byte(tm.Data))
			case "resize":
				_ = pty.Setsize(ptmx, &pty.Winsize{
					Cols: uint16(tm.Cols),
					Rows: uint16(tm.Rows),
				})
			}
		}
	}()

	// Wait for the shell process to exit
	wg.Wait()
	_ = cmd.Wait()
}
