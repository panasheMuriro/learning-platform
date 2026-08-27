# Understanding Juju Relations

Relations (or Integrations) are the core mechanism in Juju that connects distinct software components and allows them to automatically exchange connection information, credentials, and state.

## What is a Relation?

In traditional operations, connecting a web application to a database requires:
1. Creating database credentials and an empty schema.
2. Opening network firewall ports.
3. Editing configuration files (e.g. `database_url`, usernames, passwords) on the web app.
4. Restarting the web application.

In Juju, a single relation command declares the connection:

```bash
juju relate web-app postgresql
# or using modern syntax:
juju integrate web-app postgresql
```

```mermaid
graph LR
    App["Web Application (Requires: db)"] ---|Relation Hook Events & Data| DB["Database Cluster (Provides: db)"]
```

## Endpoints, Roles & Interfaces

Relations are defined in the charm's `metadata.yaml` or `charmcraft.yaml` using endpoints and interfaces:

### 1. Endpoint Roles
- **`provides`**: The charm offers a service or capability (e.g. PostgreSQL provides a `db` or `database` endpoint).
- **`requires`**: The charm consumes a capability (e.g. WordPress requires a `database` endpoint).
- **`peers`**: Units of the *same* application communicate with one another to form a cluster or quorum (e.g. PostgreSQL units syncing replication state).

### 2. Interfaces
An **interface** (e.g. `pgsql`, `mysql_client`, `http`, `ingress`) is a mutual protocol specification. Charms can only be integrated if their endpoints share compatible interface protocols.

```yaml
# In consumer charmcraft.yaml:
requires:
  database:
    interface: pgsql

# In provider charmcraft.yaml:
provides:
  db:
    interface: pgsql
```

## Explicit Endpoint Notation

If applications expose multiple compatible endpoints, specify the exact endpoint names:

```bash
juju integrate <application1>:<endpoint> <application2>:<endpoint>
```
