# Provider Authentication

The Juju Terraform provider needs to authenticate with a Juju controller. This
lecture covers the authentication methods and how to choose the right one.

## The easy way: CLI config (default)

When you use an empty provider block, the provider reads your Juju CLI
configuration:

```hcl
provider "juju" {}
```

This uses the credentials stored in `~/.local/share/juju/` — the same ones
that `juju whoami`, `juju models`, and other CLI commands use.

**Prerequisite**: You must have a bootstrapped controller and be logged in:

```bash
# Bootstrap a controller (if you haven't)
juju bootstrap localhost course

# Verify you're authenticated
juju whoami
```

If `juju whoami` works, the provider will work too. This is the method we use
throughout this course.

## How it works under the hood

The provider reads these files from your Juju config directory:

| File | Purpose |
|------|---------|
| `controllers.yaml` | Controller addresses and connection info |
| `accounts.yaml` | User credentials (passwords or certificates) |
| `models.yaml` | Current model selection |
| `credentials.yaml` | Cloud credentials (for bootstrapping) |

The provider uses the **current controller** (marked with `*` in `juju controllers`).

## Explicit controller configuration

If you need to target a specific controller (not the current one), use the
`controller_addresses` argument:

```hcl
provider "juju" {
  controller_addresses = ["10.0.0.5:17070"]

  # Username/password auth
  username = "admin"
  password = "supersecret"
}
```

## Authentication methods

### 1. CLI config (recommended for local dev)

```hcl
provider "juju" {}
```

- ✅ Easiest — zero configuration
- ✅ Works if `juju whoami` works
- ❌ Requires Juju CLI installed and configured
- ❌ Not suitable for CI/CD (no interactive login)

### 2. Username and password

```hcl
provider "juju" {
  controller_addresses = ["my-controller.example.com:17070"]
  username             = "terraform"
  password             = var.juju_password
}
```

- ✅ Works in CI/CD
- ✅ No Juju CLI needed on the runner
- ❌ Password in config (use a variable + environment variable)

### 3. Client certificate

```hcl
provider "juju" {
  controller_addresses = ["my-controller.example.com:17070"]
  cert_file            = "/path/to/client.crt"
  key_file             = "/path/to/client.key"
  ca_certificate       = file("/path/to/ca.crt")
}
```

- ✅ Most secure
- ✅ No passwords
- ❌ Requires certificate management

### 4. JAAS (OAuth2)

For Canonical's hosted JAAS controller:

```hcl
provider "juju" {
  jaas_server_url    = "https://api.jaas.canonical.com"
  client_id          = var.jaas_client_id
  client_secret      = var.jaas_client_secret
}
```

- ✅ No controller to bootstrap
- ✅ Canonical manages the infrastructure
- ❌ Requires a JAAS account
- ❌ Some features limited compared to self-hosted

## Using environment variables

For CI/CD, pass credentials via environment variables:

```bash
export TF_VAR_juju_password="supersecret"
export JUJU_CONTROLLER_ADDRESSES="my-controller:17070"
```

```hcl
variable "juju_password" {
  type      = string
  sensitive = true
}

provider "juju" {
  controller_addresses = [var.controller_address]
  username             = "terraform"
  password             = var.juju_password
}
```

## Verifying authentication

After writing your provider block, test it:

```bash
terraform init
terraform plan
```

If `terraform plan` succeeds (even with an empty config), the provider can
connect to your controller. If you see a connection error, check:

1. Is the controller running? (`juju controllers`)
2. Are you logged in? (`juju whoami`)
3. Is the controller address reachable? (`ping` or `telnet <host> 17070`)

## Next steps

Now that authentication is sorted, let's create our first Juju resources —
a model and an application.
