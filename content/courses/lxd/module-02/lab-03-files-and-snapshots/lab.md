# Lab: Files & Snapshots

In this lab, you'll transfer files between the host and the `web` container
using `lxc file push/pull`, create a snapshot, and test restore by deleting
a file and bringing it back.

## Prerequisites

- Container `web` is running (previous labs)

## What you'll do

1. Create a file inside the container
2. Pull, modify, and push the file
3. Create a snapshot
4. Delete the file and restore from snapshot
