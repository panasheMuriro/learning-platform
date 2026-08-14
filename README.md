# LXD Hands-On Course

An open-source, fully-local course platform for learning [LXD](https://canonical.com/lxd) — Canonical's system container and virtual machine manager. Built on Canonical's stack with an in-browser terminal, auto-graded labs, and interleaved lecture-lab flow.

## What this is

A hands-on training course where learners:

1. **Read lecture notes** with diagrams and code examples in a browser UI
2. **Take quizzes** (single-choice, multi-choice, text-answer) to check understanding
3. **Do hands-on labs** in an in-browser terminal — real `lxc` commands against a real LXD daemon, no leaving the browser
4. **Get auto-graded** by check scripts that run real `lxc` commands and verify results

Everything runs **locally on the learner's machine** — no cloud, no remote hosting. The in-browser terminal connects via WebSocket to a PTY shell on the host where LXD is installed.

## Quick start (developer)

> Requires Ubuntu 22.04+ with LXD installed, Go 1.22+, Bun, and Docker.

```bash
# Install go-task (once)
sudo snap install task --classic

# Install dependencies
task install

# Run in dev mode (Vite on :3000, backend on :9090, Postgres in Docker)
task dev

# Open the course in your browser
# -> http://localhost:3000

# Stop all services
task stop
```

From there: read notes, take quizzes, open a lab, type `lxc` commands in the in-browser terminal, click **Check** — all without leaving the browser.

## Repository layout

```
.
├── platform/
│   ├── frontend/      # React + Vite + Vanilla Framework + xterm.js
│   ├── backend/       # Go API server (content, quiz, PTY terminal, grading, progress)
│   └── code-server/   # Custom code-server image (for file-editing courses)
├── content/
│   └── courses/lxd/   # LXD course: lecture notes, quizzes, labs (Markdown + check.sh)
├── docs/              # Documentation
├── Taskfile.yml       # All build/dev/stop/lint commands
└── docker-compose.yml # Postgres for local dev
```

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | React 19, Vite, TypeScript, [Vanilla Framework](https://vanillaframework.io/), [xterm.js](https://xtermjs.org/) |
| Backend | Go (REST + WebSocket PTY) |
| Terminal | xterm.js ↔ WebSocket ↔ PTY shell on host |
| Database | PostgreSQL 16 (Docker) |
| Lab environment | LXD on host (assumed installed) |

## Course structure

The LXD course has **5 modules** with interleaved lectures and labs — you do hands-on work right after learning a concept, not all at the end:

| Module | Topics | Labs |
|--------|--------|------|
| **01 — Getting Started** | What is LXD, install & init, first instance | Install & Initialize, Launch First Container |
| **02 — Managing Instances** | Creating containers/VMs, configuring, shell & exec, files & snapshots | Create & Configure, Shell & Exec, Files & Snapshots |
| **03 — Images** | Remote image servers, local image management, creating images | Explore Remote Images, Manage Local Images, Publish Custom Image |
| **04 — Storage** | Storage pools & drivers, custom volumes | Explore Storage Pools, Custom Volumes |
| **05 — Networking** | Bridge networks, instance networking | Bridge Networks, Instance Networking |

Each lab's `setup.sh` checks for prerequisites from previous labs and creates missing instances if needed, ensuring continuity across the module.

## Per-course workspace type

Courses can declare `"workspace": "terminal"` or `"workspace": "code-server"` in `course.json`. The LXD course uses the in-browser terminal (CLI-based labs). The Juju+Terraform course (on the `juju-terraform` branch) uses code-server (file-editing labs with `.tf` files).

## Branches

- **`main`** — LXD course (this branch)
- **`juju-terraform`** — Juju + Terraform course (dedicated branch)

## Licensing

- **Code** (everything under `platform/`): Apache-2.0 — see [LICENSE](LICENSE)
- **Content** (everything under `content/`): CC-BY-SA 4.0

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Content contributions (notes, quizzes, labs) are especially welcome.
