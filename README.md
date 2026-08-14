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

From there: read notes, take quizzes, open a lab, edit HCL in the in-browser editor, run `terraform apply` in the in-browser terminal, click **Check** — all without leaving the browser.

## Repository layout

```
.
├── platform/
│   ├── frontend/      # React + Vite + Canonical Pragma + xterm.js + Monaco
│   └── backend/       # Go API server (content, quiz, file API, PTY, grading, progress)
├── workshop/          # Canonical Workshop SDK (bundles everything for `workshop launch`)
├── content/           # Course content: lecture notes, quizzes, labs (Markdown + check.sh)
├── docs/              # Architecture, lab authoring guide, learner setup
└── .github/           # CI workflows
```

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | React 19, Vite, TypeScript, [Canonical Pragma](https://github.com/canonical/pragma), xterm.js, Monaco |
| Backend | Go (REST + WebSocket) |
| Lab environment | [Canonical Workshop](https://github.com/canonical/workshop) + LXD + Juju + Terraform |
| Lab cloud | LXD (native, per-learner) |
| Progress store | SQLite (local, single profile) |

## Curriculum

11 modules from Foundations to a Capstone Challenge. v1 ships Module 1 (Foundations) complete; the rest are designed but deferred. See [docs/architecture.md](docs/architecture.md) for the full curriculum outline.

## Licensing

- **Code** (everything under `platform/` and `workshop/`): Apache-2.0 — see [LICENSE](LICENSE)
- **Content** (everything under `content/`): CC-BY-SA 4.0 — see [content/LICENSE](content/LICENSE)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Content contributions (notes, quizzes, labs) are especially welcome.

## Status

🚧 **Early development** — Phase 1 (scaffold) in progress. Not yet usable by learners.
