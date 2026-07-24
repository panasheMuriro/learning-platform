# What is Terraform?

Terraform is HashiCorp's open-source **Infrastructure as Code (IaC)** tool. It lets
you define, provision, and manage infrastructure using a declarative configuration
language called **HCL** (HashiCorp Configuration Language).

## Key concepts

| Concept | Description |
|---------|-------------|
| **Provider** | A plugin that talks to an API (AWS, Azure, Juju, etc.). Providers define resources. |
| **Resource** | A piece of infrastructure (a VM, a database, a Juju model). The building block of Terraform. |
| **Data source** | A read-only fetch of existing infrastructure (e.g., "get the current model"). |
| **Variable** | An input parameter — makes configs reusable. |
| **Output** | A value exposed after apply — useful for passing info to other configs or scripts. |
| **State** | A file (`terraform.tfstate`) tracking what Terraform has created. The source of truth. |
| **Module** | A reusable, packaged set of resources — like a function in programming. |

## How Terraform works

```mermaid
graph LR
    A[Write .tf files] --> B[terraform init]
    B --> C[terraform plan]
    C --> D[terraform apply]
    D --> E[Infrastructure created]
    E --> F[terraform destroy]
```

1. **Write** `.tf` files describing your desired infrastructure
2. **`terraform init`** — downloads providers, initializes the working directory
3. **`terraform plan`** — shows what Terraform will create, modify, or destroy
4. **`terraform apply`** — executes the plan, creates/updates resources
5. **`terraform destroy`** — tears down everything Terraform created

## A simple example

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "local" {}

resource "local_file" "hello" {
  filename = "hello.txt"
  content  = "Hello from Terraform!"
}
```

Run `terraform init && terraform apply` and Terraform creates `hello.txt`.

## Declarative vs imperative

Terraform is **declarative** — you describe the *end state* ("I want 3 instances")
and Terraform figures out *how* to get there. You don't write step-by-step scripts.

| | Terraform (declarative) | Bash/Ansible (imperative) |
|---|---|---|
| **You write** | "I want 3 VMs with these settings" | "Create VM 1, then VM 2, then VM 3" |
| **Re-running** | Safe — Terraform checks current state, does nothing if already correct | May create duplicates |
| **State tracking** | Yes (`terraform.tfstate`) | No (you track it yourself) |

## Terraform and Juju

Terraform manages infrastructure. Juju manages applications. The **Juju Terraform
provider** bridges them — letting you declare Juju models, applications, and
integrations as Terraform resources.

In the next lecture, we'll explore why combining them is powerful.
