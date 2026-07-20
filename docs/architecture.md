# Architecture

## Overview

The Juju + Terraform course is a **fully-local, in-browser** learning platform.
Everything runs on the learner's machine — no cloud, no remote hosting. The
`juju-terraform-course` Workshop SDK bundles the frontend, backend, and lab
environment as services that auto-start inside a Workshop container.

```
Learner machine (Ubuntu + LXD + Workshop snap)
  workshop launch -> LXD system container (the Workshop)
    |
    |-- Service: Frontend (React SPA, Canonical Pragma)
    |     Course catalog / module nav (SideNavigation, Timeline)
    |     Lecture viewer (MarkdownEditor in preview mode)
    |     Quiz component (form primitives + lifecycle badges)
    |     Lab workspace: FileTree | Monaco editor | xterm.js terminal
    |     Progress dashboard (Timeline + lifecycle badges)
    |     Served at localhost:<frontend-port>
    |
    |-- Service: Backend (Go API) - no auth
    |     Content service (serves notes/quiz/lab metadata + Markdown)
    |     Quiz scoring service
    |     File API (list/read/write files in lab working directory)
    |     PTY service (spawns real shell via creack/pty, streams over WebSocket)
    |     Grading endpoint (runs check.sh, returns pass/fail + tasks)
    |     Progress tracker (local SQLite, single local profile)
    |     Served at localhost:<backend-port>
    |
    |-- Lab env (inside the SAME Workshop container)
    |     LXD (native) + Juju snap + Terraform
    |     /home/student/<lab>/  starter files + check.sh
    |     Backend PTY service execs a shell directly here
    |
    v
  Browser (learner opens localhost:<frontend-port>)
```

## Why fully local + in-browser works

The key insight: since the backend and the learner's shell/files live in the
**same container**, the backend can spawn a real PTY directly (via `creack/pty`)
— no SSH, no bridging, no multi-tenant complexity. That complexity only appears
in a hosted/remote scenario (deferred to v2).

This means the learner gets the full KodeKloud-style experience — terminal +
editor + file tree + auto-grading — all in the browser, without leaving it.

## Component details

### Frontend (Canonical Pragma + React)

| Component | Pragma package | Purpose |
|-----------|---------------|---------|
| ApplicationLayout, SideNavigation | `@canonical/react-ds-app` | App shell + course navigation |
| MarkdownEditor (preview mode) | `@canonical/react-ds-app-launchpad` | Lecture + lab instruction rendering |
| FileTree | `@canonical/react-ds-app-launchpad` | Lab file navigation |
| Button, Card, Accordion, Timeline | `@canonical/react-ds-global` | UI primitives, progress display |
| Input, Select, Checkbox | `@canonical/react-ds-global-form` | Quiz form inputs |

**Custom components** (Pragma gaps):
- **xterm.js** — in-browser terminal, connected to backend PTY via WebSocket
- **Monaco** (`@monaco-editor/react`) — code editor for `.tf` files

### Backend (Go)

| Package | Purpose |
|---------|---------|
| `internal/content` | Serves lecture notes, quizzes, lab instructions from `content/` |
| `internal/quiz` | Evaluates quiz answers, records scores |
| `internal/files` | File API (list/read/write) with path traversal protection |
| `internal/pty` | Spawns PTY shell, streams over WebSocket to xterm.js |
| `internal/grade` | Runs `check.sh`, parses JSON result, records progress |
| `internal/progress` | SQLite store for quiz/lab/lecture completion |

### Workshop SDK

The `juju-terraform-course` SDK (via SDKcraft) bundles:
- Juju snap (`--classic`)
- Terraform (>= 1.6)
- LXD (pre-initialized with `lxdbr0`)
- Frontend + backend binaries (started as systemd services)
- Course content (seeded from `content/`)

### Lab environment

Each lab runs inside the Workshop container:
- LXD provides the Juju cloud (native, not nested-in-Docker)
- Learner bootstraps a Juju controller on `localhost` (LXD)
- Learner writes HCL, runs `terraform init/plan/apply` in the in-browser terminal
- `check.sh` runs real `terraform`/`juju` commands and emits JSON results

## Data flow

### Lecture viewing
```
Browser -> GET /api/modules/{mod}/lectures/{lec} -> Backend reads content/{mod}/notes/{lec}.md -> returns JSON {markdown} -> React renders with react-markdown
```

### Quiz
```
Browser -> GET /api/modules/{mod}/quiz -> Backend reads content/{mod}/quiz.json -> returns questions
Browser -> POST /api/modules/{mod}/quiz/submit {answers} -> Backend scores -> records in SQLite -> returns {score, passed}
```

### Lab (in-browser workspace)
```
Browser -> GET /api/modules/{mod}/labs/{lab} -> Backend reads content/{mod}/{lab}/lab.md -> returns instructions
Browser FileTree -> GET /api/files?path=... -> Backend lists directory -> returns FileEntry[]
Browser Monaco -> GET /api/files/content?path=... -> Backend reads file -> returns text
Browser Monaco -> PUT /api/files/content?path=... -> Backend writes file
Browser xterm.js -> WS /ws/terminal -> Backend spawns PTY -> streams shell I/O
Browser Check button -> POST /api/modules/{mod}/labs/{lab}/check -> Backend runs check.sh -> parses JSON -> records progress -> returns GradeResult
```

## v2 evolution (deferred)

v2 adds hosted, multi-tenant labs:
- Lab orchestrator (spawn/reset/destroy ephemeral containers per remote user)
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
