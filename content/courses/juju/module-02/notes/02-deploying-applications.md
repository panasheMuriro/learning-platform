# Deploying Applications & Placement

Deploying an application creates an application entity inside your active model and instructs the Juju controller to provision the underlying machine or container.

## The `juju deploy` Command

The basic syntax for deploying from Charmhub is:

```bash
juju deploy <charm-name> [application-alias] [flags]
```

### Deploying with an Application Name Alias

You can run multiple independent instances of the same charm by specifying an alias:

```bash
# Deploy two distinct applications from the same 'ubuntu' charm
juju deploy ubuntu web-server
juju deploy ubuntu backend-worker
```

## Specifying Channels and Bases

You can explicitly control the channel and the operating system base for the charm:

```bash
# Deploy from a specific channel
juju deploy ubuntu --channel latest/stable

# Target a specific Ubuntu operating system base
juju deploy ubuntu --base ubuntu@24.04
```

## Machine Constraints & Placement

When deploying to machine clouds (such as LXD, OpenStack, AWS, Azure, GCP), you can specify resource constraints:

```bash
# Request specific memory and CPU cores
juju deploy ubuntu web-app --constraints "mem=4G cores=2"

# Request root disk space
juju deploy ubuntu db-app --constraints "root-disk=20G mem=8G"
```

### Manual Placement (`--to`)

You can direct Juju to place an application's unit onto an existing allocated machine or container:

```bash
# Deploy directly onto machine ID 0
juju deploy ubuntu helper --to 0

# Deploy inside an LXD container hosted on machine ID 0
juju deploy ubuntu app-in-lxd --to lxd:0
```

## Deploying Multiple Units (`-n` or `--num-units`)

You can provision a scaled application immediately at deploy time:

```bash
# Deploy 3 units of ubuntu named 'cluster-node'
juju deploy ubuntu cluster-node -n 3
```
