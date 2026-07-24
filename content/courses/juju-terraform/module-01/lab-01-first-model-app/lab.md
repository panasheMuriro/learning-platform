# Lab 1: First Model + Application

In this lab, you'll create your first Juju model and deploy an application
using the Juju Terraform provider.

## Prerequisites

- A Juju controller is bootstrapped on LXD (run `juju bootstrap localhost course` if not)
- Terraform is installed (`terraform version`)
- You're in the lab working directory

## Task 1: Define the provider

Open `main.tf` and add the Terraform provider configuration for Juju:

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
```

The empty `provider "juju" {}` block uses your Juju CLI config for authentication.

<details>
<summary>💡 Hint: Where does the provider get credentials?</summary>

When `provider "juju" {}` has no arguments, it reads your Juju CLI config
(`~/.local/share/juju/`) for controller credentials. This is the easiest
auth method for local labs — as long as `juju whoami` works, the provider
will too.
</details>

## Task 2: Initialize Terraform

Run `terraform init` in the terminal to download the Juju provider.

```bash
terraform init
```

You should see the provider being downloaded and installed.

## Task 3: Create a Juju model

Add a `juju_model` resource named "development" to `main.tf`:

```hcl
resource "juju_model" "development" {
  name = "development"
}
```

<details>
<summary>💡 Hint: What does a model need?</summary>

A model needs at minimum a `name`. You can optionally specify a cloud and
region, but if omitted, Juju uses the controller's default cloud (LXD in
our case).
</details>

## Task 4: Deploy the ubuntu charm

Add a `juju_application` resource that deploys the `ubuntu` charm into the
"development" model:

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

> ⚠️ **Gotcha**: Applications reference models by `model_uuid` (computed),
> not by name. Use `juju_model.development.uuid`.

## Task 5: Plan and apply

Run `terraform plan` to see what will be created, then `terraform apply` to
create the resources:

```bash
terraform plan
terraform apply -auto-approve
```

## Task 6: Verify

Verify your deployment with Juju:

```bash
juju status --model development
```

You should see the `ubuntu` application with 1 unit in `active` status.

## Task 7: Clean up (optional)

When you're done, destroy the resources:

```bash
terraform destroy -auto-approve
```

---

✅ Click **Check** to verify your work, or run `./check.sh` in the terminal.
