# Machine Management & Provisioning

In machine-based models, Juju manages physical, virtual, or containerized machines. Operators can manually allocate machines, inspect hardware states, and directly SSH into running instances.

## Allocating Machines (`juju add-machine`)

By default, `juju deploy` automatically allocates a new machine for each unit. However, you can also pre-provision standalone machines:

```bash
# Allocate a default machine in the model
juju add-machine

# Allocate a machine with specific hardware constraints
juju add-machine --constraints "mem=8G cores=4 root-disk=40G"

# Allocate a machine with a specific base OS
juju add-machine --base ubuntu@24.04
```

## Inspecting Machines (`juju machines`)

To view all allocated machines, their IP addresses, hardware instance IDs, operating system bases, and status:

```bash
# Formatted list of machines
juju machines

# Or check the Machine table in juju status
juju status
```

```
Machine  State    Address     Inst id        Base          AZ          Message
0        started  10.0.8.10   juju-abec92-0  ubuntu@24.04  panashe-x1  Running
1        started  10.0.8.25   juju-abec92-1  ubuntu@24.04  panashe-x1  Running
```

## Accessing Machines (`juju ssh` and `juju scp`)

Juju automatically manages SSH keys across all machines and units in your model:

```bash
# SSH directly into machine ID 0
juju ssh 0

# SSH directly into a unit's container
juju ssh web/0

# Copy files to/from a unit
juju scp config.json web/0:/tmp/config.json
```

## Removing Machines (`juju remove-machine`)

To decommission a machine that no longer hosts any units:

```bash
# Gracefully remove machine 1
juju remove-machine 1

# Force remove if machine is unresponsive
juju remove-machine 1 --force
```
