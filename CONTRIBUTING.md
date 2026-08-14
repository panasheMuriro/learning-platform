# Contributing

Thanks for your interest in contributing to the Juju + Terraform course!

## Ways to contribute

- **Content** — lecture notes, quiz questions, hands-on labs (most valuable!)
- **Platform** — frontend (React/Pragma) or backend (Go) improvements
- **Workshop SDK** — environment packaging, tool versions, hooks
- **Docs** — learner setup guides, lab authoring guides
- **Issues** — bug reports, content corrections, lab ideas

## Repository layout

```
platform/frontend/   React + Vite + Pragma + xterm.js + Monaco
platform/backend/    Go API server
workshop/            Canonical Workshop SDK (bundles everything)
content/             Course content (Markdown notes, quizzes, labs)
docs/                Documentation
```

## Licensing

By contributing, you agree your contributions will be licensed under:
- **Apache-2.0** for code (under `platform/` and `workshop/`)
- **CC-BY-SA 4.0** for content (under `content/`)

## Development setup

### Prerequisites

- Node.js 22+ and Bun (frontend)
- Go 1.22+ (backend)
- LXD + Workshop snap (for running labs locally)

### Frontend

```bash
cd platform/frontend
bun install
bun run dev
```

### Backend

```bash
cd platform/backend
go run ./cmd/server
```

### Content

Content is plain Markdown + shell scripts — no build step. See
[docs/authoring-labs.md](docs/authoring-labs.md) for the lab schema.

## Content contribution guidelines

- Lecture notes: Markdown, one file per topic, under `content/module-XX/notes/`
- Quizzes: see `content/schema.md` for the quiz format
- Labs: each lab is a directory with `lab.md`, `starter/`, `check.sh`, `setup.sh`
- Follow the KodeKloud pedagogical patterns: mixed question types, collapsible
  hints (`<details>`), error-driven labs, progressive callbacks
- `check.sh` must emit JSON results (see `content/shared/check-helper.sh`)

## Code style

- Frontend: Biome (lint + format), TypeScript strict
- Backend: `gofmt` + `golangci-lint`
- Commit messages: conventional commits (`feat:`, `fix:`, `docs:`, `content:`)

## Pull requests

1. Fork and branch from `main`
2. Keep PRs focused — one feature/lab/module per PR
3. For new labs, include a tested `check.sh` that passes against a correct solution
4. Ensure CI passes (lint, test, build)
5. For content, request a technical review from a Juju team member

## Questions?

Open a discussion or issue. Happy hacking!
