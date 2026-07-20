# Juju + Terraform Hands-On Course

An open-source, fully-local course platform for learning [Juju](https://juju.is) and [Terraform](https://terraform.io) together — modeled on the KodeKloud pedagogy (notes → quiz → hands-on lab with auto-grading) and built on Canonical's stack.

## What this is

A hands-on training course where learners:

1. **Read lecture notes** in a browser UI
2. **Take a quiz** to check understanding
3. **Do hands-on labs** in an in-browser workspace (terminal + code editor + file tree) — no leaving the browser
4. **Get auto-graded** by running real `terraform`/`juju` commands against a real Juju controller on LXD

Everything runs **locally on the learner's machine** — no cloud, no remote hosting. The `juju-terraform-course` Workshop SDK bundles the frontend, backend, and lab environment (Juju + Terraform + LXD) as services that auto-start inside a Workshop container.

## Quick start (learner)

> Requires Ubuntu 22.04+ with LXD. Mac/Windows users: see [docs/learner-setup.md](docs/learner-setup.md) for the Multipass VM path.

```bash
# Install Workshop
sudo snap install --classic workshop

# Launch the course environment (bundles frontend + backend + Juju + Terraform + LXD)
workshop launch

# Open the course in your browser
# -> http://localhost:<port>  (port printed by `workshop launch`)
```

From there: read notes, take quizzes, open a lab, edit HCL in the embedded VS Code editor (code-server), run `terraform apply` in its integrated terminal, click **Check** — all without leaving the browser.

## Quick start (developer)

All build/run commands are wrapped in a [Taskfile](https://taskfile.dev) — see [Taskfile.yml](Taskfile.yml) for the full list (`task --list-all`).

```bash
# Install go-task (once)
sudo snap install task --classic

# Install dependencies
task install

# Run in dev mode (Vite hot-reload on :3000, backend on :8080, code-server on :8081)
task dev

# Build + run in production mode (single port :8080 serves everything)
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
│   ├── frontend/      # React + Vite + Canonical Vanilla Framework / react-components
│   └── backend/       # Go API server (content, quiz, file API, PTY, grading, progress)
├── workshop/          # Canonical Workshop SDK (bundles everything for `workshop launch`)
├── content/           # Course content: lecture notes, quizzes, labs (Markdown + check.sh)
├── docs/              # Architecture, lab authoring guide, learner setup
├── Taskfile.yml       # All build/dev/prod/lint/test commands (see `task --list-all`)
├── start-prod.sh      # Standalone production startup script (wrapped by `task prod`)
└── .github/           # CI workflows
```

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | React 19, Vite, TypeScript, [Vanilla Framework](https://vanillaframework.io) + [@canonical/react-components](https://github.com/canonical/react-components) |
| Lab editor/terminal | [code-server](https://github.com/coder/code-server) (VS Code in the browser, embedded via iframe) |
| Backend | Go (REST + WebSocket), serves built frontend in production |
| Lab environment | [Canonical Workshop](https://github.com/canonical/workshop) + LXD + Juju + Terraform |
| Lab cloud | LXD (native, per-learner) |
| Progress store | SQLite (local, single profile) |
| Task runner | [Taskfile](https://taskfile.dev) |

## Curriculum

11 modules from Foundations to a Capstone Challenge. v1 ships Module 1 (Foundations) complete; the rest are designed but deferred. See [docs/architecture.md](docs/architecture.md) for the full curriculum outline.

## Licensing

- **Code** (everything under `platform/` and `workshop/`): Apache-2.0 — see [LICENSE](LICENSE)
- **Content** (everything under `content/`): CC-BY-SA 4.0 — see [content/LICENSE](content/LICENSE)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Content contributions (notes, quizzes, labs) are especially welcome.

## Status

🚧 **Early development** — Module 1 (Foundations) content complete, platform functional in dev and production modes. Workshop SDK packaging not yet validated end-to-end.
