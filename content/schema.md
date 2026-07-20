# Content Schema

This document defines the structure for all course content: lectures, quizzes, and labs.

## Directory layout

```
content/
  outline.json                          # course outline (modules, lectures, labs, quiz refs)
  LICENSE                               # CC-BY-SA 4.0
  schema.md                             # this file
  shared/
    check-helper.sh                     # shared helper sourced by each lab's check.sh
  module-01/
    notes/
      01-what-is-juju.md                # lecture markdown
      02-what-is-terraform.md
      ...
    quiz.json                           # module quiz
    lab-01-first-model-app/
      lab.md                             # lab instructions (shown in browser)
      starter/                           # files copied into learner's workspace
        main.tf
        variables.tf
      check.sh                           # grading script (runs terraform/juju, emits JSON)
      setup.sh                            # per-lab environment setup
    lab-02-variables-outputs/
      ...
    lab-03-lifecycle/
      ...
  module-02/
    ...
```

## outline.json

The top-level course outline. Served at `GET /api/outline`.

```json
{
  "title": "Juju + Terraform Hands-On Course",
  "modules": [
    {
      "id": "module-01",
      "title": "Foundations: Juju, Terraform & the Provider",
      "lectures": [
        { "id": "01-what-is-juju", "title": "What is Juju?" }
      ],
      "labs": [
        { "id": "lab-01-first-model-app", "title": "First Model + Application" }
      ],
      "quiz": { "id": "module-01-quiz" }
    }
  ]
}
```

## Lecture notes

Plain Markdown files under `module-XX/notes/`. Served at `GET /api/modules/{moduleId}/lectures/{lectureId}`.

Supports GitHub-flavored Markdown. Use `<details><summary>Hint</summary>...</details>` for collapsible hints.

## Quiz format

JSON file at `module-XX/quiz.json`. Served at `GET /api/modules/{moduleId}/quiz`.

```json
{
  "moduleId": "module-01",
  "questions": [
    {
      "id": "q1",
      "prompt": "What does Juju manage?",
      "type": "single-choice",
      "options": [
        "Application lifecycle via charms",
        "Docker containers",
        "Kubernetes pods only",
        "Network firewalls"
      ],
      "answer": "Application lifecycle via charms",
      "explanation": "Juju is an Operator Lifecycle Manager (OLM) that deploys and manages applications using reusable operators called charms."
    },
    {
      "id": "q2",
      "prompt": "Which Terraform resource creates a Juju model?",
      "type": "single-choice",
      "options": ["juju_model", "juju_application", "juju_machine", "terraform_model"],
      "answer": "juju_model",
      "explanation": "The juju_model resource creates a Juju model (a namespace for applications)."
    },
    {
      "id": "q3",
      "prompt": "Select all valid juju_application attributes:",
      "type": "multi-choice",
      "options": ["model_uuid", "charm", "units", "vpc_id", "constraints"],
      "answer": ["model_uuid", "charm", "units", "constraints"],
      "explanation": "model_uuid, charm, units, and constraints are all valid. vpc_id is an AWS attribute, not Juju."
    },
    {
      "id": "q4",
      "prompt": "What command shows the planned changes Terraform will make?",
      "type": "text-answer",
      "answer": "terraform plan",
      "explanation": "terraform plan shows what Terraform will create, modify, or destroy."
    }
  ]
}
```

### Question types
- `single-choice`: one correct answer from options. `answer` is a string.
- `multi-choice`: multiple correct answers. `answer` is an array of strings. All must be selected.
- `text-answer`: free text. `answer` is a string (exact match, case-insensitive).

Passing score: 70%.

## Lab format

Each lab is a directory under `module-XX/lab-XX-name/` containing:

### lab.md
Lab instructions shown in the browser. Markdown with numbered tasks and `<details>` hints.

```markdown
# First Model + Application

## Task 1: Create a Juju model

Write a `juju_model` resource named "development"...

<details>
<summary>Hint</summary>

```hcl
resource "juju_model" "development" {
  name = "development"
}
```
</details>

## Task 2: Deploy the ubuntu charm

Add a `juju_application` resource...
```

### starter/
Files copied into the learner's workspace at lab start. Typically:
- `main.tf` — partial or empty HCL for the learner to complete
- `variables.tf` — variable definitions
- `versions.tf` — provider requirements

### check.sh
The grading script. Runs real `terraform`/`juju` commands and emits a JSON result.

Must source `content/shared/check-helper.sh` and emit JSON in this format:

```json
{
  "passed": true,
  "tasks": [
    {
      "id": "task-1",
      "name": "Create a Juju model",
      "passed": true,
      "message": "Model 'development' exists"
    },
    {
      "id": "task-2",
      "name": "Deploy the ubuntu charm",
      "passed": false,
      "message": "Application 'ubuntu' not found in model"
    }
  ]
}
```

The backend parses this JSON from check.sh's stdout. If check.sh exits non-zero
without emitting JSON, the lab is marked as failed.

### setup.sh
Per-lab environment setup. Run when the lab starts (or when "Reset" is clicked).
Typically:
- Copies `starter/` files into the learner's working directory
- Optionally pre-bootstraps a Juju controller
- Runs `terraform init` to cache providers
