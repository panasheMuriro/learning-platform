# Application Status & Health

Observing and interpreting workload status is essential for operating Juju applications effectively.

## The `juju status` Command

The primary tool for monitoring your model is `juju status`:

```bash
# Formatted tabular overview of the active model
juju status

# Continuous watch mode (updates automatically)
juju status --watch 2s

# Machine-readable JSON or YAML output
juju status --format json
juju status --format yaml
```

## Understanding the Status Output

```
Model    Controller           Cloud/Region         Version  SLA          Timestamp
lab-app  pizzeria-controller  localhost/localhost  3.6.24   unsupported  16:45:00+02:00

App       Version  Status  Scale  Charm   Channel        Rev  Exposed  Message
web-app   1.2.0    active      1  ubuntu  latest/stable   79  no       ready

Unit        Workload  Agent  Machine  Public address  Ports  Message
web-app/0*  active    idle   0        10.0.8.45              ready

Machine  State    Address    Inst id        Base          AZ          Message
0        started  10.0.8.45  juju-abec92-0  ubuntu@24.04  panashe-x1  Running
```

### 1. Workload Status (Application State)
Set directly by the charm logic to reflect the service health:
- `active`: The service is installed, configured, running, and functioning normally.
- `waiting`: The charm is waiting for an external event (e.g., waiting for machine provisioning or a relation).
- `maintenance`: The charm is executing an administrative task (e.g., running apt install or initializing databases).
- `blocked`: The charm requires operator intervention (e.g., missing mandatory configuration or license).
- `error`: An unhandled exception occurred in the charm hook execution.

### 2. Agent Status (Juju Agent State)
Reflects the condition of the Juju unit agent running on the machine:
- `idle`: The agent is ready and listening for events.
- `executing`: The agent is currently running a charm hook or action.
- `allocating`: The controller is creating or provisioning the machine container.
- `lost`: The controller has lost network heartbeat connection to the agent.

## Filtering Status

You can scope `juju status` to specific entities:

```bash
# Status for a specific model
juju status -m other-model

# Status for a specific application
juju status web-app
```
