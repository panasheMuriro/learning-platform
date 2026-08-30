# Day-2 Operations: Actions & Remote Execution

Day-2 operations in cloud environments encompass regular administrative and maintenance tasks performed after initial deployment, such as running backups, rotating certificates, clearing caches, creating snapshots, or gathering diagnostics.

## Charm Actions

Charms can define custom administrative functions called **Actions**. Unlike automated event hooks triggered by topology changes (e.g. `install`, `config-changed`), actions are invoked **on-demand by the human operator** or CI/CD pipelines.

```mermaid
graph LR
    Operator[Operator / CLI] -->|juju run app/0 do-backup| JujuController[Juju Controller]
    JujuController -->|Dispatches action| Agent[Unit Agent (db/0)]
    Agent -->|Executes handler| Script[Charm Action Logic]
    Script -->|Returns status & output| JujuController
    JujuController -->|Operation result| Operator
```

## Discovering Actions (`juju actions`)

To see what actions a deployed application supports:

```bash
juju actions <application-name>
```

Example output:
```text
Action        Description
backup        Creates a full database snapshot
restore       Restores database from an archive file
vacuum        Runs maintenance cleanup on database tables
```

To view the parameter schema and descriptions for specific actions:

```bash
juju actions <application-name> --schema
```

## Running Actions (`juju run`)

In Juju 3.x, charm actions are invoked using `juju run`:

```bash
# Run an action on a specific unit
juju run postgresql/0 backup

# Run an action with parameters
juju run postgresql/0 backup compression=zstd destination=/mnt/backups

# Run an action targeting all units in an application
juju run postgresql backup
```

### Checking Action Status & Logs

When an action executes, Juju tracks its operation ID:

```bash
# Check status and output of a running or completed action
juju show-operation <operation-id>
```

## Ad-Hoc Shell Execution (`juju exec`)

When you need to execute arbitrary bash commands across units or machines without defining a full charm action, use `juju exec`:

```bash
# Run a shell command on all units of an application
juju exec --application worker "uptime"

# Run a command on a specific unit
juju exec --unit worker/0 "df -h"

# Run a command on a specific machine
juju exec --machine 0 "free -m"
```
