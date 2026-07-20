# init/plan/apply/destroy Lifecycle

These four commands are the heart of working with Terraform. This lecture walks
through each one in detail.

## terraform init

**Purpose**: Initialize the working directory. Downloads providers, configures
the backend, prepares for plan/apply.

```bash
terraform init
```

What it does:
1. Reads `required_providers` from your `.tf` files
2. Downloads provider plugins from the Terraform Registry
3. Creates a `.terraform/` directory with provider binaries
4. Creates a `.terraform.lock.hcl` lock file (pin exact versions)

When to run it:
- **First time** in a new project
- After **adding/changing a provider** in `required_providers`
- After **cloning** a repo (`.terraform/` is not committed)

```bash
# Output looks like:
# - Installing juju/juju v2.1.1...
# - Installed juju/juju v2.1.1
# Terraform has been successfully initialized!
```

## terraform plan

**Purpose**: Show what Terraform will do — without doing it. This is your
"dry run" / "what if" command.

```bash
terraform plan
```

What it does:
1. Reads your `.tf` files
2. Reads the current state (`terraform.tfstate`)
3. Queries the real infrastructure (via the provider) to check actual state
4. Computes the diff: what needs to be created, changed, or destroyed
5. Prints a human-readable plan

Output symbols:
| Symbol | Meaning |
|--------|---------|
| `+` | Will be **created** |
| `~` | Will be **updated in-place** |
| `-` | Will be **destroyed** |
| `-/+` | Will be **destroyed and recreated** |

```bash
# Example output:
# Terraform will perform the following actions:
#
#   # juju_model.dev will be created
#   + resource "juju_model" "dev" {
#       + name = "dev"
#       + uuid = (known after apply)
#     }
#
# Plan: 1 to add, 0 to change, 0 to destroy.
```

### Saving a plan

For safety in CI/CD, save the plan to a file and apply that exact plan:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## terraform apply

**Purpose**: Execute the plan — create, update, or destroy resources.

```bash
terraform apply
```

What it does:
1. Runs a plan (same as `terraform plan`)
2. Asks for confirmation ("Do you want to perform these actions?")
3. Executes the changes via the provider API
4. Updates `terraform.tfstate` with the new state

### Auto-approve (for scripts/CI)

```bash
terraform apply -auto-approve
```

Skips the confirmation prompt. Useful in CI/CD but dangerous locally — always
run `terraform plan` first to review changes.

### Applying a saved plan

```bash
terraform apply tfplan
```

Applies the exact plan saved earlier. No re-planning, no confirmation prompt.

## terraform destroy

**Purpose**: Destroy all resources managed by this Terraform config.

```bash
terraform destroy
```

What it does:
1. Plans the destruction of ALL resources
2. Asks for confirmation
3. Destroys resources (in dependency order — children first, then parents)
4. Updates state to reflect the destruction

```bash
terraform destroy -auto-approve  # Skip confirmation
```

> ⚠️ **Warning**: `terraform destroy` removes EVERYTHING in your config. Use
> `terraform destroy -target=juju_application.ubuntu` to destroy only specific
> resources.

## The full lifecycle

```bash
# 1. Initialize
terraform init

# 2. Review what will happen
terraform plan

# 3. Create the resources
terraform apply

# 4. Make changes to your .tf files, then re-plan
terraform plan

# 5. Apply the changes
terraform apply

# 6. Clean up when done
terraform destroy
```

## State file: terraform.tfstate

The state file is Terraform's memory. It tracks:
- What resources exist
- Their current attributes
- Dependencies between resources

**Important rules:**
- **Never edit it manually** — use `terraform` commands
- **Never commit it to git** (for team projects) — use a remote backend
- **Back it up** — losing state means Terraform forgets what it created

### Useful state commands

```bash
terraform state list              # List all resources in state
terraform state show <address>    # Show details of a specific resource
terraform state pull              # Output the raw state JSON
```

## What happens when things change?

### You change your .tf file

```hcl
# Change units from 1 to 3
resource "juju_application" "ubuntu" {
  units = 3  # was 1
}
```

```bash
terraform plan  # Shows: ~ juju_application.ubuntu will be updated (units: 1 → 3)
terraform apply # Juju adds 2 more units
```

### Someone changes things via the CLI (drift)

```bash
# Someone runs via CLI:
juju remove-application ubuntu
```

```bash
terraform plan  # Shows: + juju_application.ubuntu will be created (it's gone!)
terraform apply # Re-creates the application
```

This is **drift detection** — one of Terraform's most valuable features.

## Module 1 summary

You now know:
- What Juju is (OLM, charms, models, applications)
- What Terraform is (IaC, HCL, state)
- Why combining them is powerful
- How the Juju Terraform provider works
- HCL syntax basics
- Provider authentication
- `juju_model` and `juju_application` resources
- The `init`/`plan`/`apply`/`destroy` lifecycle

**Next**: Take the quiz, then do the hands-on labs to practice!
