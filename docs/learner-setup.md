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

## Step 2: Install Task Runner

```bash
sudo snap install --classic task
```

## Step 3: Run the course

```bash
# Clone the course repository
git clone https://github.com/panasheMuriro/learning-platform.git
cd learning-platform

# Install dependencies
task install

# Start the course in dev mode (Vite UI on :3000, API on :9090)
task dev
```

Open your browser at:
```
http://localhost:3000
```

*(Note: Workshop SDK packaging via `workshop launch` is planned as a future distribution method and is currently experimental).*

## Step 4: Take the course

1. **Read lecture notes** — navigate modules in the sidebar
2. **Take quizzes** — answer questions, get instant scoring and feedback
3. **Do labs** — open a lab, then:
   - Read the instructions & hints in the lab guide panel
   - Execute commands in the in-browser terminal
   - Click **Check** on tasks to verify completion
   - See your progress update on the sidebar and module dashboard

**You never need to leave the browser.** The terminal and task verification
are all integrated in-browser.

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
starter files.
