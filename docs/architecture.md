# Architecture

## Overview

The Juju Hands-On Course is a **fully-local, in-browser** learning platform.
Everything runs on the learner's machine — no cloud, no remote hosting.

```
Learner machine (Ubuntu + LXD)
    |
    |-- Frontend (React 19 SPA, Canonical Vanilla Framework + @canonical/react-components)
    |     Course catalog / module navigation (ApplicationLayout, SideNavigation)
    |     Lecture viewer (Markdown rendering)
    |     Quiz component (form primitives, instant grading, explanations)
    |     Lab workspace: Instructions panel + in-browser terminal + Task checkers
    |     Progress dashboard
    |     Served at localhost:3000 (dev) / localhost:9090 (prod)
    |
    |-- Backend (Go API) - no auth
    |     Content service (serves notes/quiz/lab metadata + Markdown from content/)
    |     Quiz scoring service
    |     File API (list/read/write files in lab working directory)
    |     PTY service (spawns real shell via creack/pty, streams over WebSocket)
    |     Grading endpoint (runs check.sh / JSON checkers, returns task status)
    |     Progress tracker (local database, persistent profile)
    |     Served at localhost:9090
    |
    |-- Local Environment
    |     LXD (native) + Juju snap
    |     Backend PTY service execs an interactive shell on the host
    |
    v
  Browser (learner opens localhost:3000 or localhost:9090)
```

## Why fully local + in-browser works

The key insight: since the backend and the learner's shell/files live in the
**same container**, the backend can spawn a real PTY directly (via `creack/pty`)
— no SSH, no bridging, no multi-tenant complexity. That complexity only appears
in a hosted/remote scenario.

This means the learner gets the full interactive experience — terminal +
instructions + task verification + auto-grading — all in the browser, without leaving it.

## Component details

### Frontend (Canonical Design System + React)

| Component | Package | Purpose |
|-----------|---------|---------|
| ApplicationLayout, SideNavigation | `@canonical/react-components` | App shell + collapsible course navigation |
| Markdown viewer | `react-markdown` | Lecture + lab instruction rendering |
| Button, Card, Accordion | `@canonical/react-components` | UI primitives, progress display |
| Input, CheckboxInput, RadioInput | `@canonical/react-components` | Quiz form inputs |
| xterm.js | `xterm` + `xterm-addon-fit` | In-browser terminal, connected to backend PTY via WebSocket |

### Backend (Go)

| Package | Purpose |
|---------|---------|
| `internal/content` | Serves lecture notes, quizzes, lab instructions from `content/` |
| `internal/quiz` | Evaluates quiz answers, records scores |
| `internal/files` | File API (list/read/write) with path traversal protection |
| `internal/pty` | Spawns PTY shell, streams over WebSocket to xterm.js |
| `internal/grade` | Runs `check.sh` / JSON checkers, parses JSON result, records progress |
| `internal/progress` | Progress store for quiz/lab/lecture completion |

### Workshop SDK

The Workshop environment bundles:
- Juju snap (`--classic`)
- LXD (pre-initialized with `lxdbr0`)
- Frontend + backend binaries (started as systemd services)
- Course content (seeded from `content/courses/juju/`)

### Lab environment

Each lab runs inside the Workshop container:
- LXD provides the Juju cloud (native, not nested-in-Docker)
- Learner bootstraps or accesses a Juju controller on `localhost` (LXD)
- Learner runs actual `juju` commands in the in-browser terminal
- Task checkers run real `juju` commands and emit structured verification results

## Data flow

### Lecture viewing
```
Browser -> GET /api/courses/{courseId}/modules/{mod}/lectures/{lec} -> Backend reads content/courses/{courseId}/{mod}/lectures/{lec}.md -> returns JSON {markdown} -> React renders with react-markdown
```

### Quiz
```
Browser -> GET /api/courses/{courseId}/modules/{mod}/quiz -> Backend reads content/courses/{courseId}/{mod}/quiz.json -> returns questions
Browser -> POST /api/courses/{courseId}/modules/{mod}/quiz/submit {answers} -> Backend scores -> records progress -> returns {score, passed}
```

### Lab (in-browser workspace)
```
Browser -> GET /api/courses/{courseId}/modules/{mod}/labs/{lab} -> Backend reads content/courses/{courseId}/{mod}/{lab}/guide.md + tasks.json
Browser xterm.js -> WS /ws/terminal -> Backend spawns PTY -> streams shell I/O
Browser Check button -> POST /api/courses/{courseId}/modules/{mod}/labs/{lab}/check -> Backend executes checker -> returns TaskResult[]
```
- Web terminal changes from local-PTY to SSH/attach-to-remote-container
- Lab host tier, concurrency/isolation management
- Cloud hosting, auth/user accounts

The v1 in-browser terminal/editor/file-tree UI carries over unchanged — only
the backend's connection to the lab container changes.

## Curriculum

11 modules from Foundations to Capstone. See `content/outline.json` for the
full structure. v1 ships Module 1 (Foundations) complete.

| # | Module | Labs |
|---|--------|------|
| 1 | Foundations | First Model+App, Variables & Outputs, Lifecycle |
| 2 | State & Drift | Inspecting tfstate, Drift Detection, Import |
| 3 | Integrations & Multi-App | WordPress+Percona, COS Lite |
| 4 | Machines, Constraints & Config | Machines, Config & Storage, Charm Refresh |
| 5 | Data Sources & Dynamic Config | data.juju_model, count/for_each |
| 6 | Modules & Reusability | Wrap Module, Remote Module |
| 7 | Offers & Cross-Model | Offer Endpoint, Consume |
| 8 | Secrets & Access Control | juju_secret, juju_access_model |
| 9 | Controller & Cloud Management | Bootstrap, Cloud & Credentials |
| 10 | JAAS & Advanced | JAAS Auth, CI/CD |
| 11 | Capstone Challenge | Observability Stack, Multi-Model |
