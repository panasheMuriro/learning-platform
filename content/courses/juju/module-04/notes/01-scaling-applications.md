# Scaling Applications & High Availability

Horizontal scaling allows distributed services to handle increased traffic and maintain high availability when workloads surge or infrastructure fails.

## Scaling Out with `juju add-unit`

To add more units (instances) to a deployed application:

```bash
# Add a single unit to an application
juju add-unit <application-name>

# Add multiple units simultaneously
juju add-unit <application-name> -n 2
```

When new units are provisioned:
1. Juju provisions new machines or containers according to the charm's constraints.
2. The charm lifecycle runs (`install`, `config-changed`, `start`).
3. Existing relations fire `relation-joined` and `relation-changed` events so the new units integrate automatically into clusters and load balancers.

```mermaid
graph TD
    LB[Load Balancer] --> Unit0[App Unit 0]
    LB --> Unit1[App Unit 1]
    LB -.->|Auto-joined on scale-out| Unit2[App Unit 2 (New)]
```

## Scaling In with `juju remove-unit`

To reduce unit count or decommission a specific unit:

```bash
# Remove a specific unit
juju remove-unit <application-name>/<unit-number>
# e.g.:
juju remove-unit worker/1

# Remove multiple specific units
juju remove-unit worker/1 worker/2

# Remove units without prompt
juju remove-unit worker/1 --no-prompt
```

When a unit is removed:
1. Juju fires `relation-departed` and `relation-broken` on related applications.
2. The charm executes the `stop` hook to flush queues and deregister cleanly.
3. The underlying machine or container is released if no other units share it.

## Kubernetes vs Machine Scaling

- On **Machine clouds** (LXD, OpenStack, AWS, Azure, GCP): Use `juju add-unit` and `juju remove-unit`.
- On **Kubernetes clouds** (MicroK8s, EKS, GKE, AKS): Use `juju scale-application <app> <count>` (e.g., `juju scale-application web 5`).
