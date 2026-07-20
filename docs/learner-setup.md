# Learner Setup

## Prerequisites

- **Ubuntu 22.04 or 24.04** (recommended)
- **8 GB RAM minimum** (16 GB recommended for LXD + Juju)
- **50 GB free disk space**
- **LXD** installed and initialized

### Mac / Windows users

Workshop requires Linux + LXD. Use [Multipass](https://multipass.run) to run
an Ubuntu VM:

```bash
# Install Multipass
# macOS:  brew install --cask multipass
# Windows: download from https://multipass.run

# Create an Ubuntu 24.04 VM with enough resources
multipass launch --name course-vm --cpus 4 --memory 8G --disk 50G 24.04

# Shell into the VM
multipass shell course-vm
```

Then continue with the Linux instructions below, inside the VM.

## Step 1: Install LXD

```bash
sudo snap install lxd
lxd init --auto
```

Verify:
```bash
lxc list  # should return an empty list, no errors
```

## Step 2: Install Workshop

```bash
sudo snap install --classic workshop
```

Verify:
```bash
workshop --version
```

## Step 3: Launch the course

```bash
# Clone the course repository (or use the published SDK)
git clone https://github.com/juju-tf-course/juju-tf-course.git
cd juju-tf-course

# Launch the Workshop — this bundles:
#   - Frontend (React app)
#   - Backend (Go API)
#   - Juju + Terraform + LXD
workshop launch
```

Workshop will print the port for the frontend. Open it in your browser:

```
http://localhost:<port>
```

## Step 4: Take the course

1. **Read lecture notes** — navigate modules in the sidebar
2. **Take quizzes** — answer questions, get instant feedback
3. **Do labs** — open a lab, then:
   - Read the instructions (shown in the browser)
   - Edit `.tf` files in the **Monaco editor** (left pane)
   - Run commands in the **terminal** (bottom pane) — `terraform init`, `terraform apply`, etc.
   - Click **Check** to auto-grade your work
   - See your progress update on the dashboard

**You never need to leave the browser.** The terminal, editor, and file tree
are all in-browser. (Power users can also use `workshop shell` or VS Code connect
if they prefer.)

## Troubleshooting

### `juju bootstrap` fails

Ensure LXD is running and has storage configured:
```bash
lxc profile show default
lxc storage list
```

If storage is missing:
```bash
lxd init
# Accept defaults, or specify a ZFS pool
```

### Terminal doesn't connect

The in-browser terminal connects via WebSocket to the backend. Ensure:
- The backend service is running inside the Workshop
- No firewall is blocking localhost ports
- Try refreshing the page

### `terraform init` fails to download provider

The Juju provider is downloaded from the Terraform Registry. If you're offline,
you may need to pre-cache it. The Workshop SDK should handle this, but if not:
```bash
terraform providers lock
```

### Resetting a lab

Click **Reset** in the lab UI, or run `./setup.sh` in the terminal to restore
starter files.
