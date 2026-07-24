# juju_model & juju_application

These are the two most fundamental Juju Terraform resources. Together, they let
you create a model and deploy a charm into it.

## juju_model

A **model** is a workspace/namespace for applications. Every application must
belong to a model.

```hcl
resource "juju_model" "development" {
  name = "development"
}
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `name` | ✅ Yes | The model name (must be unique on the controller) |
| `cloud` | No | Cloud block (name + region). Defaults to controller's cloud. |
| `config` | No | Map of model config values (e.g., `{ default-series = "jammy" }`) |
| `credential` | No | Cloud credential name. Defaults to controller's. |

### Cloud block

```hcl
resource "juju_model" "aws_prod" {
  name = "production"
  cloud {
    name   = "aws"
    region = "us-east-1"
  }
}
```

For LXD (local labs), you can omit the cloud block — the controller's default
LXD cloud is used:

```hcl
resource "juju_model" "local_dev" {
  name = "local-dev"
  # cloud omitted — uses controller's default (LXD)
}
```

### Config block

```hcl
resource "juju_model" "configured" {
  name = "configured"
  config = {
    default-series     = "jammy"
    agent-metadata-url = "https://..."
    logging-config     = "<root>=DEBUG"
  }
}
```

### Attributes

After creation, the model has computed attributes you can reference:

| Attribute | Description |
|-----------|-------------|
| `uuid` | The model's UUID — **used by applications to reference the model** |
| `type` | The model type (`iaas` for machine models, `caas` for K8s) |
| `credential` | The credential used |

## juju_application

An **application** is a deployed charm. It runs inside a model.

```hcl
resource "juju_application" "ubuntu" {
  name       = "ubuntu"
  model_uuid = juju_model.development.uuid
  charm {
    name    = "ubuntu"
    channel = "latest/stable"
  }
  units = 1
}
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `name` | ✅ Yes | Application name (unique within the model) |
| `model_uuid` | ✅ Yes | The model's UUID — use `juju_model.<name>.uuid` |
| `charm` | ✅ Yes | Charm block (name, channel, revision, base) |
| `units` | No* | Number of units to deploy. Default: 1. (*Required for non-subordinate charms) |
| `config` | No | Map of charm config values |
| `constraints` | No | Placement constraints (e.g., `"mem=4G cores=2"`) |
| `expose` | No | Block to expose the application's endpoints |
| `trust` | No | Grant the charm access to cloud credentials (K8s) |
| `machines` | No | List of machine IDs to place units on |

### Charm block

```hcl
charm {
  name     = "postgresql"     # Required — charm name on Charmhub
  channel  = "14/stable"      # Required — release track
  revision = 142              # Optional — pin to a specific revision
  base     = "ubuntu@22.04"   # Optional — target OS base
}
```

### The model_uuid gotcha

This is the #1 beginner mistake:

```hcl
# ✅ Correct — reference the computed uuid attribute
resource "juju_application" "app" {
  model_uuid = juju_model.dev.uuid
  # ...
}

# ❌ Wrong — there is no "model" argument that takes a name string
resource "juju_application" "app" {
  model = "dev"   # ERROR: no such argument
  # ...
}
```

The `model_uuid` is computed by Terraform after the model is created. Terraform
automatically handles the dependency — it creates the model first, then the
application.

### Units vs machines

- `units = 3` — Juju provisions 3 machines and deploys one unit on each
- `machines = ["0", "1"]` — deploy on specific machines (implies unit count)
- You **cannot** set both `units` and `machines` — they're mutually exclusive

### Subordinate charms

Subordinate charms (like `nrpe`, `telegraf`) don't have their own units. Omit
the `units` field entirely:

```hcl
resource "juju_application" "nrpe" {
  name       = "nrpe"
  model_uuid = juju_model.dev.uuid
  charm {
    name    = "nrpe"
    channel = "latest/stable"
  }
  # No units field — subordinate charm
}
```

## Complete example

```hcl
terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 2.1.0"
    }
  }
}

provider "juju" {}

resource "juju_model" "dev" {
  name = "dev"
}

resource "juju_application" "ubuntu" {
  name       = "ubuntu"
  model_uuid = juju_model.dev.uuid
  charm {
    name    = "ubuntu"
    channel = "latest/stable"
  }
  units = 1
}

output "model_uuid" {
  value = juju_model.dev.uuid
}

output "app_name" {
  value = juju_application.ubuntu.name
}
```

## Next steps

Now let's see how to actually run this — the `init`/`plan`/`apply`/`destroy`
lifecycle.
