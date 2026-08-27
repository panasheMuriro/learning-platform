# Lab 2: Inspect, Update & Reset Application Configuration

## Overview
In this lab, you will configure a deployed application using `juju config`, apply custom configuration values, and verify reverting options with `--reset`.

## Objectives
1. Create a model named `lab-config` and deploy `ubuntu` as `custom-node`.
2. Configure `hostname` to `worker-01` on `custom-node`.
3. Deploy a second application named `helper-node`, configure its `hostname` to `temp-host`, and then reset it back to the default setting.
