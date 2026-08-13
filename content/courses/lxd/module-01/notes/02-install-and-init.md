# Installing & Initializing LXD

LXD is installed via **snap** on most Linux distributions. Snap is the
recommended installation method and ensures you get the latest version.

## Installing LXD

```bash
sudo snap install lxd
```

If LXD is already installed, check the version:

```bash
lxd --version
```

To update an existing installation:

```bash
sudo snap refresh lxd
```

## Adding your user to the lxd group

After installing LXD, your user must be in the `lxd` group to interact with
the LXD daemon without `sudo`:

```bash
sudo usermod -aG lxd "$USER"
newgrp lxd
```

> **Security note**: Local access to LXD through the Unix socket grants full
> access to LXD, equivalent to root access. Only add trusted users to the
> `lxd` group.

## Initializing LXD

After installation, initialize LXD with a minimal configuration:

```bash
lxd init --minimal
```

The `--minimal` flag sets up LXD with sensible defaults:
- A ZFS storage pool (if available) or directory-backed storage
- A default bridge network (`lxdbr0`)
- No clustering

If you want more control, run `lxd init` without `--minimal` and answer the
interactive prompts. You can always re-run `lxd init` later to change settings.

## Verifying the installation

```bash
lxc list
```

If LXD is installed and initialized correctly, this should return an empty
table (no instances yet) with no errors.

```mermaid
graph LR
    A[snap install lxd] --> B[usermod -aG lxd]
    B --> C[newgrp lxd]
    C --> D[lxd init --minimal]
    D --> E[lxc list]
    E --> F[✅ Ready!]
```

## Preseed configuration

For automated setups, you can pass a YAML configuration file to `lxd init`:

```bash
lxd init --preseed < preseed.yaml
```

This is useful for CI/CD pipelines and production deployments where you need
reproducible configurations.

## Next steps

Now that LXD is installed and initialized, let's launch our first instance!
