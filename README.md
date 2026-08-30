# Juju Hands-On Course

An open-source, fully-local interactive course platform for learning [Juju](https://juju.is) — modeled on the KodeKloud pedagogy (notes → quiz → hands-on lab with auto-grading) and built on Canonical's stack.

## What this is

A comprehensive, hands-on enterprise training curriculum for Juju 3.x+ where learners:

1. **Read lecture notes** in a modern Canonical Design System UI
2. **Take quizzes** to check understanding with instant scoring and explanations
3. **Do hands-on labs** in an in-browser workspace (terminal + code editor + task verification) — no leaving the browser
4. **Get auto-graded** by running real `juju` and system commands against a real Juju controller on LXD

Everything runs **locally on the learner's machine** — no cloud, no remote hosting. The Workshop environment bundles the frontend, backend, and lab environment (Juju + LXD) as services that auto-start seamlessly.

## Screenshots

### Course Overview & Progress Dashboard
![Course Overview & Module Dashboard](docs/images/course-overview.png)

### In-Depth Interactive Lectures
![Interactive Lecture Viewer](docs/images/lecture-view.png)

### Split-Pane Hands-On Lab Workspace
![In-Browser Terminal & Real-Time Task Verification](docs/images/lab-workspace.png)

### Knowledge Check Quizzes with Instant Grading
![Module Assessment Quiz](docs/images/quiz-assessment.png)

## Quick start

### Running with Taskfile (Recommended)

Requires Ubuntu 22.04+ (or any Linux/Mac environment with Go, Node/Bun, and LXD).

```bash
# Clone the repository
git clone https://github.com/panasheMuriro/learning-platform.git
cd learning-platform

# Install task runner (once)
sudo snap install task --classic

# Install dependencies (Go modules + frontend dependencies)
task install

# Run the platform (Vite dev server on :3000, Go backend on :9090)
task dev
```

Open your browser at `http://localhost:3000`.

From there: read notes, take quizzes, open a lab, execute commands in the in-browser terminal, click **Check** to verify each task — all without leaving the browser.

### Production mode

```bash
# Build and run single-port server (:9090 serves frontend + API)
task prod
```

### Canonical Workshop SDK (Experimental / In Development)

Packaging the platform as a self-contained [Canonical Workshop](https://github.com/canonical/workshop) SDK (`workshop launch`) is currently experimental and under active development. For the best experience right now, use `task dev` or `task prod` as shown above.

## Development & Testing

All build/run commands are wrapped in a [Taskfile](https://taskfile.dev) — see [Taskfile.yml](Taskfile.yml) for the full list (`task --list-all`).

```bash
# Install go-task (once)
sudo snap install task --classic

# Install dependencies
task install

# Run in dev mode (Vite hot-reload on :3000, backend on :9090, code-server on :8081)
task dev

# Build + run in production mode (single port :9090 serves everything)
task prod

# Lint / format / test
task lint
task format
task test

# Stop all running services (backend, frontend dev server, code-server)
task clean
```

See [docs/architecture.md](docs/architecture.md) for how the pieces fit together.

## Repository layout

```
.
├── platform/
│   ├── frontend/      # React 19 + Vite + Canonical Vanilla Framework & @canonical/react-components
│   └── backend/       # Go API server (content, quiz, file API, PTY, grading, progress)
├── workshop/          # Canonical Workshop SDK (bundles everything for `workshop launch`)
├── content/           # Course content: 8 modules of lecture notes, quizzes, labs, and checkers
├── docs/              # Architecture, lab authoring guide, learner setup
├── Taskfile.yml       # All build/dev/prod/lint/test commands (see `task --list-all`)
├── start-prod.sh      # Standalone production startup script (wrapped by `task prod`)
└── .github/           # CI workflows
```

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | React 19, Vite, TypeScript, [Vanilla Framework](https://vanillaframework.io) + [@canonical/react-components](https://github.com/canonical/react-components) (LXD-UI aligned) |
| Lab editor/terminal | [code-server](https://github.com/coder/code-server) & in-browser WebSocket PTY terminal |
| Backend | Go 1.23 (REST + WebSocket + JSON checker grading), serves built frontend in production |
| Lab environment | [Canonical Workshop](https://github.com/canonical/workshop) + LXD + Juju 3.x+ |
| Lab cloud | LXD (native, per-learner) |
| Progress store | SQLite / PostgreSQL (local, persistent progress) |
| Task runner | [Taskfile](https://taskfile.dev) |

## Curriculum

8 comprehensive enterprise modules covering the complete Juju lifecycle:

1. **Module 1: Architecture, Clouds & Models** — Concepts, client/controller architecture, cloud credentials, model lifecycles, and context switching.
2. **Module 2: Deploying Charms & Applications** — Charmhub ecosystem, application deployment, channels, placement, and configuration.
3. **Module 3: Relations & Integration Architecture** — Endpoints, interfaces, relation data exchange, cross-application integration, and lifecycle hooks.
4. **Module 4: Scaling, High Availability & Machine Management** — Unit scaling, machine provisioning, constraints, spaces, and storage pools.
5. **Module 5: Day-2 Operations: Actions, Secrets & Cross-Model Relations** — Executing actions, Juju 3.x+ managed secrets lifecycle, and cross-model offers (CMR).
6. **Module 6: Kubernetes & Cloud-Native Operations** — K8s cloud bootstrapping, sidecar charms, Pebble containers, and k8s resources.
7. **Module 7: Observability & Canonical Observability Stack (COS)** — Logging, COS Lite integrations (Prometheus, Loki, Grafana), metrics, and troubleshooting.
8. **Module 8: Production Operations, Upgrades & Lifecycle** — Charm refresh, Juju agent upgrades, controller backup/restore, and model migration.

## Licensing

- **Code** (everything under `platform/` and `workshop/`): Apache-2.0 — see [LICENSE](LICENSE)
- **Content** (everything under `content/`): CC-BY-SA 4.0 — see [content/LICENSE](content/LICENSE)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Content contributions (notes, quizzes, labs) are welcome.

## Status

✅ **Curriculum Complete** — All 8 Juju modules (25 lectures, 16 hands-on labs, 33 quizzes) are fully authored and functional in dev and production modes.
