# Lab 2: Logging, Diagnostics & Hook Troubleshooting

In this lab, you will diagnose unit status, inspect live and replayed debug logs, examine low-level agent files, and simulate hook resolution workflows.

## Objectives
1. Create and switch to the model `mod7-troubleshoot-lab`.
2. Deploy the `ubuntu` charm as `worker-node`.
3. Query Juju debug log replay (`juju debug-log --replay --no-tail -n 20`).
4. Execute remote unit agent inspections on `/var/log/juju/` using `juju exec`.
5. Verify unit resolution commands with `juju resolved`.

