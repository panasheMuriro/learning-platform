# Lab 1: COS Machine Telemetry & Subsystem Logging

In this lab, you will configure fine-grained subsystem logging on a Juju model, deploy workload services with the `grafana-agent` telemetry forwarder, and verify subordinate integration.

## Objectives
1. Create and switch to the model `mod7-cos-lab`.
2. Configure fine-grained model logging targeting uniter workers (`logging-config="<root>=INFO;unit=DEBUG;juju.worker.uniter=TRACE"`).
3. Deploy the principal workload application `web-app` (`ubuntu` charm).
4. Deploy the `grafana-agent` machine subordinate charm.
5. Integrate `web-app` and `grafana-agent` via the `cos-agent` relation.

