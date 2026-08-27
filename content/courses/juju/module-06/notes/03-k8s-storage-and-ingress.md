# Kubernetes Storage, Ingress & Helm Deployments

Operating microservices in Kubernetes requires managing persistent volumes, external traffic ingress routing, and deploying pre-packaged container resources.

## Kubernetes Storage Pools in Juju

In Kubernetes models, Juju utilizes K8s `StorageClass` definitions as storage pools.

```bash
# List K8s storage pools (StorageClasses)
juju storage-pools

# Deploy a database charm with dynamic PVC provisioning
juju deploy postgresql-k8s --storage pgdata=10Gi
```

## Ingress and Service Exposure

Ingress in Juju is managed through charm relations. Modern K8s charms integrate with Ingress Controller charms (such as `nginx-ingress-integrator` or `traefik-k8s`):

```bash
# Deploy Traefik ingress controller
juju deploy traefik-k8s ingress --channel latest/edge

# Relate application to ingress controller
juju relate web-app:ingress ingress:ingress
```

Traefik automatically reads routing rules, hostnames, and ports from the relation data and configures Kubernetes ingress resources dynamically.

## Custom Workload Resource OCI Images

K8s charms often use OCI image resources defined in `metadata.yaml`. Operators can override the container image deployed by Juju:

```bash
# Attach custom container image to charm resource
juju attach-resource web-app app-image=myregistry.example.com/myapp:v2.1
```
