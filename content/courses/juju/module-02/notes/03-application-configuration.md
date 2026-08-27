# Application Configuration & Resources

Charms expose dynamic configuration settings that operators can inspect and adjust without needing to manually SSH into machines or rebuild containers.

## Inspecting Configuration (`juju config`)

To view all available configuration keys, descriptions, types, and active values for an application:

```bash
# View all configuration settings
juju config <application-name>

# Query a single key's value
juju config <application-name> hostname
```

### Configuration Output Example

When viewing configuration for an application, Juju outputs:
- **Default value**: The upstream default defined by the charm author.
- **Current value**: The live value active in the model.
- **Source**: Indicates whether the value is from `default` or `user`.

## Updating Application Configuration

You can update one or multiple settings simultaneously using `key=value` pairs:

```bash
# Set a single configuration parameter
juju config <application-name> hostname="node-prod-01"

# Set multiple configuration parameters
juju config <application-name> port=8080 debug=true environment="production"
```

### Passing Configuration from a YAML File

For bulk configuration management or automation pipelines:

```bash
juju config <application-name> --file my-config.yaml
```

```yaml
# my-config.yaml
hostname: web-prod-01
port: 8080
debug: false
```

## Resetting Configuration (`--reset`)

To revert any user-configured setting back to its charm default:

```bash
# Reset a single parameter to default
juju config <application-name> --reset hostname

# Reset multiple parameters
juju config <application-name> --reset port,debug
```

## Managing Charm Resources

Some charms rely on external resources (such as proprietary binary blobs or OCI images):

```bash
# List resources attached to an application
juju resources <application-name>

# Attach a local resource file
juju attach-resource <application-name> my-binary=./dist/app.tar.gz
```
