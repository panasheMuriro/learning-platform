# Instance Networking

Each instance connects to a network through a **NIC device**. By default,
instances get a `nic` device connected to `lxdbr0`. But you can customize
this — add more NICs, change networks, or use different NIC types.

## Viewing an instance's network devices

```bash
lxc config device show first
```

This shows all devices, including the network interface. You'll see
something like:

```
eth0:
  type: nic
  network: lxdbr0
```

## Adding a second NIC

You can add additional network interfaces to an instance:

```bash
lxc config device add first eth1 nic \
  network=lxdbr0
```

Now the instance has two interfaces — `eth0` (default) and `eth1` (the one
you just added).

## Connecting to a different network

If you created a second bridge, you can connect an instance to it:

```bash
lxc config device set first eth0 network=my-bridge
```

This moves the instance's `eth0` from `lxdbr0` to `my-bridge`.

## Network device types

| NIC type | Description |
|----------|-------------|
| **bridged** | Connected to a LXD-managed bridge (default) |
| **macvlan** | Directly on the physical network, own MAC address |
| **routed** | Traffic routed through the host, instance gets host's IP |
| **physical** | Pass-through of a host NIC |

## Checking connectivity

```bash
# From the host, ping an instance's IP
ping 10.10.10.10

# From inside an instance, check its interfaces
lxc exec first -- ip addr

# From inside an instance, test internet connectivity
lxc exec first -- ping -c 3 8.8.8.8
```

## Why customize networking?

- **Isolation**: Separate networks for different security zones
- **Multi-homing**: An instance connected to multiple networks
- **Direct LAN access**: macvlan for instances that need to be on the physical network
- **Testing**: Simulate network topologies

## Next steps

Now let's practice creating networks and connecting instances in the lab.
