# k3s Dev Environment

Use the `dev` flow when you need Kubernetes-specific validation on your local cluster.

## Tooling explained

- Kubernetes or `k8s` is the API and runtime model for the repo's cluster manifests.
- k3s is the lightweight Kubernetes distribution used locally.
- `kubectl` is the CLI you use to inspect the cluster when helper scripts are not enough.
- Kustomize assembles the base manifests and the `dev` overlay before they are applied.

## Main path

```bash
mise run k8s-preflight
mise run k8s-build-images
mise run k8s-import-images
mise run k8s-deploy-dev
mise run k8s-status
mise run k8s-access
```

## What each step is for

### `mise run k8s-preflight`

- checks that your cluster and required capabilities are available,
- should be the first command before deeper k3s work.

### `mise run k8s-build-images`

- builds the local backend and frontend images for the `dev` overlay,
- writes the active image tags to `.gitops-local/k3s/dev-images.env`,
- gives later steps an exact image set to reuse.

### `mise run k8s-import-images`

- imports the just-built images into k3s containerd,
- makes sure the cluster can use the same images you built locally.

### `mise run k8s-deploy-dev`

- renders and applies the `dev` overlay,
- waits for PostgreSQL and the migration job,
- waits for backend and frontend workloads,
- runs smoke checks.

This is the point where the repo stops being "just app code" and becomes a real
Kubernetes exercise: manifests, services, ingress, jobs, and cluster state all matter.

### `mise run k8s-status`

- shows workload, service, and ingress status in `atlas-platform-dev`.

### `mise run k8s-access`

- prints host mappings and access URLs,
- helps you reach the environment after deployment.

## Expected hostnames

- `atlas.local`
- `api.atlas.local`

## Useful supporting commands

- `mise run k8s-smoke`
- `mise run k8s-delete-dev`
- `mise run k8s-doctor`

If you are learning, also try `kubectl get pods -n atlas-platform-dev` after
deployment so the Kubernetes objects become concrete.

## Read next

- [GitOps bootstrap](gitops-bootstrap.md)
- [k3s runbook](../deployment/k3s/RUNBOOK.md)
