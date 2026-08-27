# Relating Applications & Inspecting Integrations

Integrating applications is how multi-tier architectures are assembled and orchestrated in Juju.

## Integrating Applications (`juju integrate`)

To establish a relation between two applications:

```bash
# Basic syntax
juju integrate <app1> <app2>

# With explicit endpoints
juju integrate web-app:db-backend postgresql:db
```

*Note: `juju relate` is an alias for `juju integrate`.*

## Inspecting Relations (`juju status` and `juju relations`)

You can inspect all active relations within your model:

```bash
# Formatted relation list
juju relations

# Machine-readable output
juju status --format json
```

### Example `juju relations` Output

```
Relation provider  Requirer      Interface  Type
postgresql:db      web-app:db    pgsql      regular
haproxy:reverseproxy web-app:http http       regular
```

## Breaking Relations (`juju remove-relation`)

When you want to disconnect two integrated applications or decouple services:

```bash
# Remove relation between two applications
juju remove-relation web-app postgresql

# Remove with explicit endpoints
juju remove-relation web-app:db-backend postgresql:db
```

When a relation is removed, Juju fires `relation-broken` and `relation-departed` events on both charms, giving them the chance to revoke credentials, flush queues, or switch to standalone mode.
