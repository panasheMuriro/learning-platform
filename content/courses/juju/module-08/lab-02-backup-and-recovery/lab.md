# Lab 2: Controller Backup, Recovery & Logging Verification

In this lab, you will generate Juju controller backup archives, inspect backup metadata, configure model logging verbosity, and verify disaster-recovery procedures.

## Objectives
1. Create and switch to model `mod8-backup-lab`.
2. Generate a controller backup archive using `juju create-backup`.
3. List available controller backups using `juju backups`.
4. Configure model logging verbosity targeting uniter workers (`logging-config="<root>=INFO;unit=DEBUG;juju.worker.uniter=TRACE"`).
5. Verify non-blocking log replay using `juju debug-log --replay --no-tail -n 10`.
