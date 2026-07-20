# Lab 2: Variables & Outputs

In this lab, you'll make your Terraform config reusable with variables and
expose useful values with outputs.

## Prerequisites

- Completed Lab 1 (or have a working Juju controller on LXD)
- Terraform initialized in your working directory

## Task 1: Define variables

Create a `variables.tf` file with the following variables:

```hcl
variable "model_name" {
  type        = string
  default     = "lab-02"
  description = "Name of the Juju model to create"
}

variable "charm_name" {
  type        = string
  default     = "ubuntu"
  description = "Name of the charm to deploy"
}

variable "charm_channel" {
  type        = string
  default     = "latest/stable"
  description = "Channel to deploy the charm from"
}

variable "unit_count" {
  type        = number
  default     = 1
  description = "Number of units to deploy"
}
```

## Task 2: Use variables in main.tf

Update `main.tf` to use these variables instead of hardcoded values:

```hcl
resource "juju_model" "lab" {
  name = var.model_name
}

resource "juju_application" "app" {
  name       = var.charm_name
  model_uuid = juju_model.lab.uuid
  charm {
    name    = var.charm_name
    channel = var.charm_channel
  }
  units = var.unit_count
}
```

<details>
<summary>💡 Hint: Why use variables?</summary>

Variables let you reuse the same config for different environments. You can
override them with `-var` flags or `.tfvars` files:

```bash
terraform apply -var="unit_count=3" -var="model_name=production"
```
</details>

## Task 3: Define outputs

Create an `outputs.tf` file:

```hcl
output "model_uuid" {
  value       = juju_model.lab.uuid
  description = "The UUID of the created model"
}

output "model_name" {
  value = juju_model.lab.name
}

output "app_name" {
  value = juju_application.app.name
}

output "app_units" {
  value = juju_application.app.units
}
```

## Task 4: Initialize and apply

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

## Task 5: Check outputs

After apply, view your outputs:

```bash
terraform output
```

You should see:
```
app_name = "ubuntu"
app_units = 1
model_name = "lab-02"
model_uuid = "..."
```

Get a specific output value:

```bash
terraform output model_name
```

## Task 6: Override variables

Apply with different variable values (without changing the files):

```bash
terraform apply -var="unit_count=2" -var="model_name=lab-02-custom" -auto-approve
```

Then verify:
```bash
juju status --model lab-02-custom
terraform output model_name
```

<details>
<summary>💡 Hint: What happens to the old model?</summary>

The old `lab-02` model will be **destroyed** and the new `lab-02-custom` model
will be created. Terraform sees that the `name` attribute changed, so it
destroys the old model and creates a new one. This is a **destroy-and-recreate**
operation — be careful with name changes in production!
</details>

## Task 7: Clean up

```bash
terraform destroy -auto-approve
```

---

✅ Click **Check** to verify your work, or run `./check.sh` in the terminal.
