# Creating Containers & VMs

LXD supports two types of instances: **system containers** and **virtual
machines**. Both are created with the same `lxc` commands — the `--vm` flag
is the only difference.

## System containers

System containers share the host kernel. They're lightweight, start in
seconds, and behave like a full Linux system (with `init`, users, packages).

```bash
# Create and start a container
lxc launch ubuntu:24.04 web-server

# Create but don't start
lxc init ubuntu:24.04 db-server
```

## Virtual machines

VMs have their own kernel and boot via KVM. They provide stronger isolation
and can run different operating systems, but use more resources and take
longer to start.

```bash
# Create and start a VM
lxc launch ubuntu:24.04 my-vm --vm

# Create a VM with custom memory
lxc launch ubuntu:24.04 my-vm --vm --config limits.memory=4GiB
```

## Choosing between containers and VMs

| Factor | Container | VM |
|--------|-----------|-----|
| **Startup time** | Seconds | Minutes |
| **Memory overhead** | Minimal | ~256MB+ for kernel |
| **Kernel** | Shared with host | Own kernel |
| **Security isolation** | Process-level | Hardware-level |
| **Different OS kernel** | ❌ No | ✅ Yes |
| **Nested virtualization** | N/A | Possible with support |

## Instance types in `lxc list`

The `TYPE` column in `lxc list` shows whether an instance is a container
or a VM:

```
+-------------+---------+---------------------+------------+-----------+
| NAME        | STATE   | IPV4                | TYPE       | SNAPSHOTS |
+-------------+---------+---------------------+------------+-----------+
| web-server  | RUNNING | 10.10.10.20 (eth0) | CONTAINER  | 0         |
| my-vm       | RUNNING | 10.10.10.30 (eth0) | VIRTUAL-MACHINE | 0     |
+-------------+---------+---------------------+------------+-----------+
```

## Creating instances with configuration

You can set configuration options at creation time using `--config`:

```bash
lxc launch ubuntu:24.04 limited \
  --config limits.cpu=2 \
  --config limits.memory=512MiB
```

## Using profiles

Profiles are reusable sets of configuration. The `default` profile is applied
to every instance unless you specify otherwise:

```bash
# Create an instance with a specific profile
lxc launch ubuntu:24.04 web --profile default --profile custom-profile
```

## Next steps

Now that you can create both containers and VMs, let's learn how to configure
running instances.
