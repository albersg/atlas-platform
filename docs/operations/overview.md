# Panorama operativo

Esta seccion organiza el modelo operativo actual del repositorio para `local`,
`dev` y `staging` sin mezclarlo con una futura superficie de produccion.

## Matriz de entornos

| Entorno | Objetivo | Modelo |
| --- | --- | --- |
| Local | Desarrollo rapido de app | Docker Compose o procesos locales |
| `dev` | Laboratorio k3s local | k3s + imagenes locales + overlays |
| `staging` | Validacion GitOps preproductiva canonica | Argo CD + SOPS + registry + digests |
| `staging-local` | Wrapper local de aprendizaje para staging | Argo CD + SOPS + imagenes locales `:main` |

## Flujo recomendado para `dev`

```bash
mise run k8s-preflight
mise run k8s-build-images
mise run k8s-import-images
mise run k8s-deploy-dev
mise run k8s-status
mise run k8s-access
```

`mise run k8s-build-images` genera tags locales unicos por build y guarda el estado
activo en `.gitops-local/k3s/dev-images.env`. Los pasos de import y deploy reutilizan
ese estado para desplegar exactamente las mismas imagenes que acabas de construir.

## Flujo recomendado para `staging`

Prerequisitos:

- Argo CD instalado,
- credential del repo instalada en `argocd`,
- clave `age` de SOPS instalada en `argocd`.

Flujo tipico:

```bash
mise run gitops-bootstrap-core
mise run gitops-install-age-key
mise run gitops-install-repo-credential
ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
mise run k8s-status-staging
mise run k8s-access-staging
```

En local, `mise run gitops-deploy-staging` construye e importa por defecto imagenes
con refs `ghcr.io/...:main` y sincroniza Argo CD contra `platform/k8s/overlays/staging-local`.
Ese wrapper mantiene la topologia GitOps de `staging`, pero deja claro que la fuente
de verdad canonica sigue siendo `platform/k8s/overlays/staging` con imagenes por digest.
El camino canonico tambien exige que esos digests tengan firma Cosign verificable desde
`Release Images` en GitHub Actions.

Si necesitas probar el camino registry-first del overlay canonico:

```bash
mise run k8s-doctor
mise run k8s-validate-overlays
STAGING_LOCAL_IMAGES=0 ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
```

## Checks operativos utiles

Smoke checks:

```bash
mise run k8s-smoke
mise run k8s-smoke-staging
```

Estado:

```bash
mise run k8s-status
mise run k8s-status-staging
```

Acceso:

```bash
mise run k8s-access
mise run k8s-access-staging
```

Elimination de overlays:

```bash
mise run k8s-delete-dev
ATLAS_CONFIRM_STAGING_DELETE=atlas-platform-staging mise run k8s-delete-staging
```

`k8s-delete-staging` elimina primero la Application de Argo CD sin cascada para frenar
`self-heal`, muestra los recursos afectados y preserva por defecto el `Namespace`
`atlas-platform-staging` junto con los PVC de PostgreSQL. Usa `PRESERVE_POSTGRES_PVC=0`
solo si tambien quieres borrar almacenamiento y namespace.

Backup y restore de PostgreSQL no productivo:

```bash
mise run k8s-backup-postgres-staging
BACKUP_FILE=.gitops-local/backups/staging/<timestamp>.dump \
ATLAS_CONFIRM_POSTGRES_RESTORE=atlas-platform-staging \
mise run k8s-restore-postgres-staging
```

El restore es destruction por definition: exige confirmation explicita, valida que el dump
exista y re-ejecuta migraciones + smoke checks antes de informar exito.

## Runbooks detallados

- [Runbook de despliegue en k3s](../deployment/k3s/RUNBOOK.md)
- [Runbook GitOps con Argo CD, KSOPS y SOPS](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md)
- [Promocion de imagenes por digest](../deployment/releases/IMAGE_PROMOTION.md)
- [Agent-First DevSecOps Playbook](../AGENT_FIRST_DEVSECOPS_PLAYBOOK.md)
