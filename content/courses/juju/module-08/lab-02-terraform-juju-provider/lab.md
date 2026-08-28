# Lab 2: Terraform Juju Provider IaC Workflow

In this lab, you will author Terraform HCL manifests for the Juju provider, declare models, applications, and integrations as code, and apply the infrastructure.

## Objectives
1. Create a working directory and author `main.tf` using the `juju/juju` provider syntax.
2. Define a `juju_model` resource for `tf-iac-lab`.
3. Define two `juju_application` resources (`frontend` and `database`).
4. Apply the configuration using Terraform / OpenTofu or simulate the Juju controller state.
5. Verify that the declared infrastructure matches the active environment.
