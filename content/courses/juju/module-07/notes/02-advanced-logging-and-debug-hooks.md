# Advanced Juju Logging & Debugging

When operating complex systems or troubleshooting charm hook execution, Juju provides rich, structured logging and interactive debugging facilities.

## Juju Debug Logs (`juju debug-log`)

The `debug-log` command streams real-time log entries from controller and unit agents across models.

```bash
# Stream live logs for the active model
juju debug-log

# Replay past logs without waiting for new events
juju debug-log --replay --no-tail -n 100

# Filter logs for a specific application or unit
juju debug-log --include webapp/0

# Limit logs to specific log levels (e.g. WARNING, ERROR, INFO, DEBUG, TRACE)
juju debug-log --level DEBUG
```

## Configuring Model and Subsystem Logging Levels

Log verbosity can be tuned dynamically without restarting services:

```bash
# Set global logging level on a model
juju model-config logging-config="<root>=DEBUG"

# Target specific charm subsystems (e.g. juju.worker.uniter, unit agent)
juju model-config logging-config="<root>=INFO;unit=DEBUG;juju.worker.uniter=TRACE"
```

## Interactive Hook Debugging (`juju debug-hooks`)

When a charm hook encounters an unhandled error or hook failure, Juju marks the unit in a `hook-failed` error state. Developers and operators can interactively step through and debug the hook execution in real time:

```bash
# Interactively intercept hook executions for a unit
juju debug-hooks <application>/<unit>

# In another terminal, retry the failed hook
juju resolved <application>/<unit> --retry
```

When the hook triggers, Juju opens an interactive tmux session directly inside the unit environment with all hook context variables exported.

```mermaid
graph LR
    subgraph DebugFlow [Hook Debugging Session]
        HookError[Hook Enters Error State] --> DebugCmd["juju debug-hooks unit/0"]
        DebugCmd --> ResolvedCmd["juju resolved unit/0 --retry"]
        ResolvedCmd --> TmuxShell[Interactive Tmux Environment on Target Unit]
    end
```

## Inspecting Unit Agents & Directories

On machine charms, each unit agent manages state within its own filesystem paths:

```bash
# Inspect machine-level agent logs directly
juju exec --unit webapp/0 "sudo tail -n 50 /var/log/juju/unit-*.log"

# Inspect charm state and dispatch files
juju exec --unit webapp/0 "sudo ls -la /var/lib/juju/agents/unit-*"
```

