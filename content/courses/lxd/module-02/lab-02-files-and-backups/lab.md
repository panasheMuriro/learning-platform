# Lab 2: Files & Backups

In this lab, you'll transfer files between the host and a container using
`lxc file push/pull`, create a snapshot, and test restore by deleting a file
and bringing it back.

## Prerequisites

- LXD is installed and initialized
- You have a running container (the lab setup will create one if needed)

## What you'll do

1. Create a file inside a container
2. Pull it to the host and modify it
3. Push it back to the container
4. Create a snapshot
5. Delete the file and restore from snapshot
