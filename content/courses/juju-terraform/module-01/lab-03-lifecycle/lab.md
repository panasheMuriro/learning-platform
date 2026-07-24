# Lab 3: Plan/Apply/Destroy Lifecycle

In this lab, you'll practice the full Terraform lifecycle — init, plan, apply,
modify, re-apply, inspect state, and destroy. You'll also observe drift detection.

## Prerequisites

- Completed Labs 1 and 2
- A Juju controller on LXD

## Task 1: Initialize

The starter `main.tf` has a basic config. Initialize Terraform:

```bash
terraform init
```

<details>
<summary>💡 What should you see?</summary>

You should see the Juju provider being downloaded:
```
- Installing juju/juju v2.1.1...
- Installed juju/juju v2.1.1
Terraform has been successfully initialized!
```

A `.terraform/` directory and `.terraform.lock.hcl` file will be created.
</details>

## Task 2: Plan

Run `terraform plan` and observe the output:

```bash
terraform plan
```

You should see:
- `+` symbols (resources to be **created**)
- `Plan: 2 to add, 0 to change, 0 to destroy`

<details>
<summary>💡 What do the + symbols mean?</summary>

The `+` prefix means Terraform will **create** this resource. Other symbols:
- `~` — update in-place
- `-` — destroy
- `-/+` — destroy and recreate

Since nothing exists yet, everything shows as `+` (create).
</details>

## Task 3: Apply

Create the resources:

```bash
terraform apply -auto-approve
```

Verify with Juju:
```bash
juju status --model lab-03
```

You should see the `ubuntu` application with 1 unit in `active` status.

## Task 4: Inspect state

Terraform tracks what it created in `terraform.tfstate`. Inspect it:

```bash
# List all resources in state
terraform state list

# Show details of the model
terraform state show juju_model.lifecycle

# Show details of the application
terraform state show juju_application.ubuntu
```

<details>
<summary>💡 What's in the state file?</summary>

The state file contains:
- Resource types and names
- All attributes (including computed ones like `uuid`)
- Dependencies between resources
- The Terraform version that created it

You can view the raw JSON with `terraform state pull`, but **never edit it manually**.
</details>

## Task 5: Modify and re-apply

Change the `units` count from 1 to 2 in `main.tf`:

```hcl
resource "juju_application" "ubuntu" {
  # ...
  units = 2  # was 1
}
```

Now plan and apply:

```bash
terraform plan    # Should show: ~ juju_application.ubuntu will be updated (units: 1 → 2)
terraform apply -auto-approve
```

Verify Juju added a second unit:
```bash
juju status --model lab-03
```

## Task 6: Observe drift

Simulate someone making a change via the CLI (bypassing Terraform):

```bash
juju remove-application ubuntu --model lab-03
```

Now run `terraform plan`:

```bash
terraform plan
```

<details>
<summary>💡 What do you see?</summary>

Terraform detects that the `ubuntu` application no longer exists in Juju, even
though it's still in the Terraform state. The plan shows:
```
+ juju_application.ubuntu will be created
```

This is **drift detection** — Terraform noticed the real world doesn't match
the desired state.
</details>

## Task 7: Reconcile drift

Fix the drift by re-applying:

```bash
terraform apply -auto-approve
```

Terraform re-creates the `ubuntu` application. Verify:
```bash
juju status --model lab-03
```

## Task 8: Destroy

Clean up all resources:

```bash
terraform destroy -auto-approve
```

Verify everything is gone:
```bash
juju models  # lab-03 should no longer exist
terraform state list  # should be empty
```

<details>
<summary>💡 What does destroy do?</summary>

`terraform destroy`:
1. Plans the destruction of ALL resources
2. Destroys them in dependency order (application first, then model)
3. Updates state to reflect the destruction

The state file will be empty (no resources). The `terraform.tfstate` file itself
still exists but contains no resources.
</details>

---

✅ Click **Check** to verify your work, or run `./check.sh` in the terminal.

**Note**: The check script verifies that you've completed the lifecycle — it
checks that state was created, modified, and then destroyed. Make sure to run
`terraform destroy` before checking!
