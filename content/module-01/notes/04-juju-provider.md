# The Juju Terraform Provider

The Juju Terraform provider (`juju/juju`) lets you manage Juju resources
declaratively with Terraform. It connects to a Juju controller and manages
models, applications, integrations, machines, and more.

## Installation

The provider is automatically downloaded when you run `terraform init` with the
`required_providers` block:

```hcl
terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 2.1.0"
    }
  }
}
```

- **Source**: `juju/juju` (on the Terraform Registry)
- **Latest version**: 2.1.1 (as of July 2026)
- **Terraform requirement**: >= 1.6
- **Juju requirement**: >= 2.9.49

## Provider configuration

The simplest configuration uses your Juju CLI credentials:

```hcl
provider "juju" {}
```

This reads your `~/.local/share/juju/` config — the same credentials `juju whoami`
uses. As long as you can run `juju` commands, the provider will work.

### Alternative authentication methods

| Method | When to use |
|--------|-------------|
| **CLI config** (default) | Local development — easiest. Requires `juju whoami` to work. |
| **Username/password** | CI/CD pipelines where you can't run `juju register` |
| **Client certificate** | Secure environments with cert-based auth |
| **OAuth2 (JAAS)** | When using Canonical's hosted JAAS controller |

For this course, we use the CLI config method — you've already bootstrapped a
controller, so it just works.

## Resources overview

The provider exposes these main resources:

| Resource | Purpose |
|----------|---------|
| `juju_model` | Create a Juju model (workspace) |
| `juju_application` | Deploy a charm as an application |
| `juju_integration` | Create a relation between two applications |
| `juju_machine` | Provision a machine (VM) in a cloud |
| `juju_offer` | Expose an endpoint for cross-model integration |
| `juju_secret` | Create a Juju secret |
| `juju_user` | Manage controller users |
| `juju_ssh_key` | Add SSH keys to a model |
| `juju_cloud` | Register a cloud with the controller |
| `juju_credential` | Manage cloud credentials |
| `juju_controller` | Bootstrap a new controller |
| `juju_access_model` | Set access control on a model |

And data sources:

| Data source | Purpose |
|-------------|---------|
| `data.juju_model` | Read an existing model |
| `data.juju_application` | Read an existing application |
| `data.juju_machine` | Read an existing machine |
| `data.juju_offer` | Read an existing offer |

## Key gotchas

### 1. Applications reference models by `model_uuid`, not name

```hcl
# ✅ Correct — use the computed uuid attribute
resource "juju_application" "app" {
  model_uuid = juju_model.my_model.uuid
}

# ❌ Wrong — there is no "model" attribute that takes a name
resource "juju_application" "app" {
  model = "my_model"  # This will fail!
}
```

### 2. No bundle support
The provider deploys charms individually. To deploy a "bundle" (multiple charms
with pre-configured relations), use a Terraform **module** that wraps multiple
`juju_application` and `juju_integration` resources.

### 3. Provider talks to ONE controller
The provider connects to a single controller. For cross-model integrations across
controllers, configure `offering_controllers` in the provider block.

### 4. State drift from CLI changes
If someone runs `juju deploy` or `juju remove-application` via the CLI, Terraform
state becomes stale. Run `terraform plan` to detect drift, and `terraform apply`
to reconcile.

## Next steps

Before we start writing Juju resources, let's cover HCL basics — the syntax
you'll use throughout this course.
