# Authoring Labs

This guide explains how to create new labs for the Juju Hands-On Course.

## Lab structure

Each lab is a directory under `content/courses/juju/module-XX/lab-XX-name/`:

```
content/courses/juju/module-01/lab-01-explore-controller/
  guide.md        # Step-by-step instructions and explanations
  tasks.json      # Structured task definitions, hints, solution commands, and verification checkers
```

## 1. Write guide.md

Write instructions in Markdown. Follow practical pedagogical patterns:

- **Clear task objectives** — break the lab into small, logical steps
- **Commands & code examples** — illustrate canonical `juju` command syntax
- **Verification steps** — explain how to inspect outcomes (`juju status`, `juju models`, `juju show-controller`)
- **Troubleshooting tips** — provide context for common error states and edge cases

## 2. Define tasks.json

The `tasks.json` file contains structured task verification definitions that the platform executes:

```json
{
  "tasks": [
    {
      "id": "task-1",
      "title": "Register a custom client cloud definition",
      "instructions": "Add a custom cloud definition named 'lab-cloud' using the interactive cloud command or yaml spec.",
      "hints": [
        "Use 'juju add-cloud lab-cloud' or test cloud registration"
      ],
      "solution": "juju add-cloud --client lab-cloud cloud-config.yaml",
      "checker": {
        "command": "juju clouds --format json | jq -e 'has(\"lab-cloud\")'",
        "expectedExitCode": 0
      }
    }
  ]
}
```

## 3. Register the lab in outline.json

Ensure the lab is declared in `content/courses/juju/outline.json` under the appropriate module:

```json
{
  "id": "lab-01-explore-controller",
  "title": "Inspect Client, Clouds & Controllers"
}
```

## 4. Test your lab

1. Start the course: `task dev`
2. Open the browser at `http://localhost:3000`, navigate to your lab
3. Follow your own instructions to complete the lab
4. Click **Check** — verify it passes with a correct solution
5. Break your solution — verify **Check** fails with helpful messages

## Pedagogical guidelines

- **One concept per task** — don't combine too many things in one step
- **Progressive complexity** — start easy, build up
- **Reference earlier labs** — "This is similar to Task 3 in Lab 1…"
- **Real tooling** — checkers run actual `juju` commands, not static checks
