#!/usr/bin/env bash
# start-prod.sh — Run the course platform in production mode.
#
# This starts:
#   1. code-server (VS Code in browser) on port 8081
#   2. The Go backend on port 8080, serving:
#      - REST API (/api/*)
#      - WebSocket terminal (/ws/terminal)
#      - Built frontend (static files from dist/)
#
# The learner opens http://localhost:8080 and gets everything:
# course navigation, lectures, quizzes, lab instructions, and
# the VS Code editor (via iframe to port 8081).
#
# Usage:
#   ./start-prod.sh [--lab-root /path/to/labs] [--content /path/to/content]
#
# Prerequisites:
#   - Backend binary: platform/backend/server (run `go build ./cmd/server` first)
#   - Frontend build: platform/frontend/dist/ (run `bun run build` first)
#   - code-server: running on port 8081 (Docker or installed locally)
#   - Juju + LXD installed (for labs to actually work)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults
LAB_ROOT="${LAB_ROOT:-/tmp/lab-test}"
CONTENT_DIR="${CONTENT_DIR:-${SCRIPT_DIR}/content}"
FRONTEND_DIR="${SCRIPT_DIR}/platform/frontend/dist"
BACKEND_BIN="${SCRIPT_DIR}/platform/backend/server"
DB_PATH="${DB_PATH:-${LAB_ROOT}/course.db}"
CODE_SERVER_PORT="${CODE_SERVER_PORT:-8081}"
BACKEND_PORT="${BACKEND_PORT:-8080}"
CODE_SERVER_PASSWORD="${CODE_SERVER_PASSWORD:-lab123}"

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --lab-root) LAB_ROOT="$2"; shift 2 ;;
    --content) CONTENT_DIR="$2"; shift 2 ;;
    --frontend) FRONTEND_DIR="$2"; shift 2 ;;
    --port) BACKEND_PORT="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "============================================"
echo "  Juju Hands-On Course — Production Mode"
echo "============================================"
echo ""
echo "  Backend:     http://localhost:${BACKEND_PORT}"
echo "  code-server: http://localhost:${CODE_SERVER_PORT}"
echo "  Lab root:    ${LAB_ROOT}"
echo "  Content:     ${CONTENT_DIR}"
echo "  Frontend:    ${FRONTEND_DIR}"
echo ""

# --- 1. Start code-server (if not already running) ---
if ! lsof -i:${CODE_SERVER_PORT} >/dev/null 2>&1; then
  echo "Starting code-server on port ${CODE_SERVER_PORT}..."
  if command -v docker >/dev/null 2>&1; then
    # Build the course's code-server image (Terraform pre-installed) and run
    # it with host networking + read-only access to the host's Juju client
    # config, so labs can reach an already-bootstrapped local Juju controller.
    docker build -t course-code-server "${SCRIPT_DIR}/platform/code-server" >/dev/null
    docker run -d --name code-server \
      --network host \
      -v "${LAB_ROOT}:/home/coder/project" \
      -v "${HOME}/.local/share/juju:/home/coder/.local/share/juju:ro" \
      -e PASSWORD="${CODE_SERVER_PASSWORD}" \
      -e JUJU_DATA=/home/coder/.local/share/juju \
      course-code-server \
      --bind-addr 0.0.0.0:${CODE_SERVER_PORT} \
      --trusted-origins '*' \
      /home/coder/project 2>/dev/null || true
  elif command -v code-server >/dev/null 2>&1; then
    # Run code-server directly (if installed locally)
    code-server --bind-addr 0.0.0.0:${CODE_SERVER_PORT} \
      --auth password \
      --password "${CODE_SERVER_PASSWORD}" \
      "${LAB_ROOT}" &
  else
    echo "WARNING: code-server not found. Install it or run Docker."
    echo "  Docker: docker run --network host -v ${LAB_ROOT}:/home/coder/project -e PASSWORD=${CODE_SERVER_PASSWORD} course-code-server --bind-addr 0.0.0.0:${CODE_SERVER_PORT} /home/coder/project"
  fi
  echo "code-server started."
else
  echo "code-server already running on port ${CODE_SERVER_PORT}."
fi

# --- 2. Ensure lab directory exists ---
mkdir -p "${LAB_ROOT}"

# --- 3. Start the backend (serves API + frontend) ---
echo "Starting backend on port ${BACKEND_PORT}..."
cd "${SCRIPT_DIR}/platform/backend"
exec ./server \
  --addr ":${BACKEND_PORT}" \
  --content "${CONTENT_DIR}" \
  --lab-root "${LAB_ROOT}" \
  --db "${DB_PATH}" \
  --frontend "${FRONTEND_DIR}" \
  --code-server-url "http://localhost:${CODE_SERVER_PORT}"
