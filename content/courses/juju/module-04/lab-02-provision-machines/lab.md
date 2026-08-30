# Lab 2: Machine Provisioning & Placement

## Overview
In this lab, you will manually provision an isolated machine in the model and deploy an application explicitly targeted to that machine using `--to`.

## Objectives
1. Create a model named `lab-machines`.
2. Provision a standalone machine using `juju add-machine`.
3. Deploy `ubuntu` as `custom-node` placed directly on machine `0` using `juju deploy ubuntu custom-node --to 0`.
