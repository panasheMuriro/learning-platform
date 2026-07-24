# HCL Basics

HCL (HashiCorp Configuration Language) is the language Terraform uses. It's
declarative, human-readable, and designed for infrastructure configuration.

## File structure

Terraform configs are written in `.tf` files. A typical project has:

```
.
├── main.tf       # Main resources
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output definitions
└── versions.tf   # Provider version constraints
```

You can put everything in one file, but splitting is conventional.

## Blocks

HCL is built on **blocks**. Each block has a type, labels, and a body:

```hcl
block_type "label1" "label2" {
  argument = "value"
  nested_block {
    inner_arg = "value"
  }
}
```

### Common block types

| Block | Purpose |
|-------|---------|
| `terraform` | Terraform settings (required providers, backend) |
| `provider` | Provider configuration |
| `resource` | Define a piece of infrastructure |
| `data` | Read existing infrastructure |
| `variable` | Define an input |
| `output` | Define an output |
| `locals` | Define local values (computed once) |

## Resources

The `resource` block is the most important — it creates infrastructure:

```hcl
resource "juju_model" "development" {
  name = "development"
}
```

- `"juju_model"` — the resource **type** (from the provider)
- `"development"` — the **local name** (how you reference it in other blocks)
- Inside the braces — **arguments** (configuration for this resource)

### Referencing resources

Use `resource_type.local_name.attribute`:

```hcl
resource "juju_model" "dev" {
  name = "dev"
}

resource "juju_application" "app" {
  model_uuid = juju_model.dev.uuid   # Reference the model's uuid
  name       = "myapp"
  # ...
}
```

## Variables

Variables make configs reusable:

```hcl
# variables.tf
variable "model_name" {
  type        = string
  default     = "development"
  description = "Name of the Juju model to create"
}

# main.tf
resource "juju_model" "main" {
  name = var.model_name   # Reference with var.<name>
}
```

### Variable types

```hcl
variable "count" {
  type    = number
  default = 1
}

variable "tags" {
  type    = list(string)
  default = ["web", "prod"]
}

variable "config" {
  type = map(string)
  default = {
    region = "us-east-1"
    env    = "production"
  }
}
```

## Outputs

Outputs expose values after `terraform apply`:

```hcl
output "model_uuid" {
  value       = juju_model.dev.uuid
  description = "The UUID of the created model"
}
```

View outputs with `terraform output` or `terraform output model_uuid`.

## Expressions

HCL supports expressions for dynamic values:

```hcl
# String interpolation
name = "app-${var.environment}"

# Conditional
units = var.production ? 3 : 1

# Functions
name = lower(var.app_name)
cidr = cidrsubnet("10.0.0.0/16", 8, var.subnet_index)

# Lists
machines = ["machine-1", "machine-2", "machine-3"]
first    = machines[0]

# Maps
config = {
  port     = 5432
  password = var.db_password
}
```

## Comments

```hcl
# Single-line comment (preferred)

// Also a single-line comment

/* Multi-line
   comment */
```

## A complete example

```hcl
# versions.tf
terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 2.1.0"
    }
  }
}

# main.tf
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
  units = var.unit_count
}

# variables.tf
variable "unit_count" {
  type    = number
  default = 1
}

# outputs.tf
output "model_name" {
  value = juju_model.dev.name
}
```

## Next steps

Now you know HCL basics. Next, we'll look at how the Juju provider authenticates
— then we'll write our first real Juju resources.
