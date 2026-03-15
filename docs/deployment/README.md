# Deployment Runbooks

Use this section when the lighter guides in `docs/operations/` are no longer
enough and you need the full operator playbook.

## Read this section after the overview pages

Start with these teaching pages first:

- [Operations overview](../operations/overview.md) for the full environment map.
- [k3s dev environment](../operations/k3s-dev.md) for the shortest local cluster path.
- [GitOps bootstrap](../operations/gitops-bootstrap.md) for first-time Argo CD and SOPS setup.
- [Staging-local](../operations/staging-local.md) to rehearse the staging topology on k3s.
- [Canonical staging](../operations/canonical-staging.md) for the real pre-production contract.
- [Release workflow](../operations/release-workflow.md) and [Staging promotion](../operations/staging-promotion.md) before changing digests.

## Which runbook should you open?

| Runbook | Read it when | Main prerequisites | Continue with |
| --- | --- | --- | --- |
| [k3s runbook](k3s/RUNBOOK.md) | You need cluster-level commands for `dev`, `staging-local`, backups, restore, teardown, or direct `kubectl` inspection. | Local k3s cluster, `kubectl`, `docker`, `mise`. | GitOps runbook, troubleshooting, or environment-specific operations pages. |
| [GitOps runbook](gitops/ARGOCD_SOPS_RUNBOOK.md) | You are bootstrapping or operating Argo CD, KSOPS, SOPS, and repo credentials for staging flows. | k3s or another target cluster, age key, repo access, GitOps tools. | Canonical staging, staging-local, or image promotion. |
| [Image promotion runbook](releases/IMAGE_PROMOTION.md) | You are promoting canonical `staging` to exact released image digests. | Release digests, GitHub workflow access, SOPS validation inputs. | Canonical staging verification and backup or rollback planning. |

## Environment model before you go deeper

| Environment | What it is for | What drives it |
| --- | --- | --- |
| Local Compose | Fast application development without Kubernetes. | Docker Compose helpers. |
| `dev` | Local k3s validation with locally built images. | Direct `kubectl apply` style helper commands. |
| `staging-local` | Local rehearsal of the staging topology on k3s. | Argo CD plus local `:main` image refs. |
| Canonical `staging` | Real pre-production contract. | Argo CD plus registry images pinned by digest. |

The most common source of confusion is mixing `staging-local` and canonical
`staging`. `staging-local` teaches the GitOps flow on your machine. Canonical
`staging` is the real digest-driven environment you promote and verify.

## What success looks like

You should be able to answer these questions before leaving this section:

- Which environment should I use for this task?
- Which command sequence is safe for that environment?
- What does each command change in the cluster or in GitOps state?
- How do I confirm the system is healthy before I move on?
- Which page should I read next if something fails?

## Read next

- [Troubleshooting](../reference/troubleshooting.md)
- [Command reference](../reference/commands.md)
- [Configuration and environment variables](../reference/configuration.md)
