# Lab 1: Declarative Juju Bundles & Overlays

In this lab, you will author a declarative Juju bundle YAML manifest, apply environment-specific overlays, deploy the stack, and export the live state.

## Objectives
1. Create and switch to the model `mod8-bundle-lab`.
2. Write a declarative bundle file `bundle.yaml` specifying multi-app topology (`web` and `backend`).
3. Write an overlay file `prod-overlay.yaml` overriding application scale.
4. Deploy the bundle with the overlay.
5. Export the live deployed model topology into `exported-bundle.yaml`.
