# Managing Local Images

Once images are downloaded to your local LXD server, you can manage them —
view details, add aliases, export, import, and delete.

## Listing local images

```bash
lxc image list
```

Output:

```
+--------------+--------------+--------+------------------------------------+--------------+--------+----------+
| ALIAS        | FINGERPRINT  | PUBLIC | DESCRIPTION                        | ARCH          | TYPE   | SIZE     |
+--------------+--------------+--------+------------------------------------+--------------+--------+----------+
| ubuntu/24.04 | a1b2c3d4e5f6 | no     | Ubuntu 24.04 LTS server (2024...) | x86_64        | CONTAINER | 150MB  |
+--------------+--------------+--------+------------------------------------+--------------+--------+----------+
```

## Image details

```bash
lxc image show <fingerprint-or-alias>
```

This shows the full image metadata: architecture, creation date, properties,
and the image type (container or VM).

## Adding aliases

Aliases are human-readable names for images. You can add your own:

```bash
lxc image alias add my-ubuntu <fingerprint>
```

Now you can use `my-ubuntu` instead of the fingerprint:

```bash
lxc launch my-ubuntu my-container
```

## Deleting aliases

```bash
lxc image alias delete my-ubuntu
```

## Exporting images

Export an image to a file (useful for backup or transfer):

```bash
lxc image export <fingerprint-or-alias> /path/to/export
```

This creates two files: `<fingerprint>.rootfs` and `<fingerprint>.meta`.

## Importing images

Import an image from a file:

```bash
lxc image import /path/to/image.tar.gz --alias my-custom-image
```

## Deleting local images

```bash
lxc image delete <fingerprint-or-alias>
```

> **Note**: You can't delete an image that's in use by a running instance.
> Stop or delete the instance first.

## Image properties

Images have properties like `os`, `release`, `version`, and `architecture`:

```bash
lxc image info <fingerprint-or-alias>
```

## Next steps

Finally, let's learn how to create your own images from existing instances.
