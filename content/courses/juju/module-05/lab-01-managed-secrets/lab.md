# Lab 1: Managed Secrets Lifecycle

## Overview
In this lab, you will practice managing sensitive credentials in Juju 3.x using the controller's built-in secrets engine. You will create a managed secret, verify its properties, and grant access to an application.

## Objectives
1. Create a model named `lab-secrets`.
2. Deploy the `ubuntu` charm as `web-service`.
3. Create a secret named `app-token` containing key `token=supersecret123`.
4. Grant access to `app-token` for application `web-service`.
