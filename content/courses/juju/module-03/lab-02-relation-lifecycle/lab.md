# Lab 2: Manage Relation Lifecycles & Disconnections

## Overview
In this lab, you will practice breaking an existing relation and verifying that application integrations are decoupled cleanly.

## Objectives
1. Create a model named `lab-unrelate`.
2. Deploy two `haproxy` applications (`gateway` and `api-service`) and integrate them (`gateway:reverseproxy` -> `api-service:website`).
3. Break the relation using `juju remove-relation`.
