# Why Combine Juju + Terraform?

Juju and Terraform solve different problems. Together, they provide a complete
**Infrastructure to Application** pipeline — all declarative, all as code.

## The problem they solve together

```
Day 0: Provision infrastructure     → Terraform
Day 1: Deploy applications           → Juju (via Terraform)
Day 2+: Operate, scale, integrate   → Juju (via Terraform)
```

Without integration, you'd need:
- Terraform to create VMs/networks/storage
- Then manually run `juju bootstrap`, `juju deploy`, `juju add-relation`
- Then hope nobody changes things via CLI (state drift)

With the Juju Terraform provider, the **entire stack** is one declarative config:

```hcl
# Infrastructure (Terraform + cloud provider)
resource "aws_instance" "db" {
  # ... VM provisioning
}

# Application lifecycle (Terraform + Juju provider)
resource "juju_model" "production" {
  name = "production"
}

resource "juju_application" "postgresql" {
  name       = "postgresql"
  model_uuid = juju_model.production.uuid
  charm {
    name    = "postgresql"
    channel = "14/stable"
  }
  units = 3
}
```

## Benefits of combining them

### 1. Single source of truth
Both infrastructure and application topology live in `.tf` files. `terraform plan`
shows the full picture — what VMs will be created AND what apps will be deployed.

### 2. Reproducibility
Clone the repo, run `terraform apply`, get an identical environment. No manual
steps, no "tribal knowledge" about which charms to deploy in what order.

### 3. GitOps workflow
Infrastructure and application config are version-controlled. Code review, CI/CD,
and rollback all apply to your Juju deployments — not just your cloud resources.

### 4. Drift detection
Run `terraform plan` to see if someone changed things via the `juju` CLI. Terraform
state catches drift that would otherwise go unnoticed.

### 5. Dependency management
Terraform understands dependencies. If a model must exist before an application,
Terraform creates them in the right order automatically:

```hcl
resource "juju_model" "dev" {
  name = "dev"
}

resource "juju_application" "app" {
  model_uuid = juju_model.dev.uuid  # Terraform knows: create model first
  # ...
}
```

## When to use each

| Scenario | Use |
|----------|-----|
| Provision VMs, networks, storage | Terraform (with cloud provider) |
| Deploy and operate applications | Juju (via Terraform provider) |
| Scale an application from 3 to 5 units | Juju via Terraform (change `units = 5`) |
| Add a relation between two apps | Juju via Terraform (`juju_integration`) |
| Bootstrap a Juju controller | Juju CLI or `juju_controller` resource |
| Manage day-2 operations (upgrades, config) | Juju (charms handle this continuously) |

## What the Juju Terraform provider does NOT replace

- **Juju CLI** — still useful for ad-hoc operations, debugging, `juju ssh`
- **Charms** — the provider deploys charms; it doesn't replace them
- **Juju controller operations** — some advanced controller management is CLI-only
- **Bundles** — the provider doesn't support bundle deployment directly; use
  Terraform modules to emulate bundles

## Next steps

Now that we understand *why*, let's look at the Juju Terraform provider in detail —
what resources it exposes and how to configure it.
