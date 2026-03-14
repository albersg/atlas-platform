# Runbook de despliegue en k3s

Este runbook cubre el uso de k3s como entorno no productivo para `dev` y `staging`.

## Topología local

- `platform/k8s/base`: manifiestos comunes de aplicación.
- `platform/k8s/components/in-cluster-postgres`: PostgreSQL como `StatefulSet` con volumen persistente.
- `platform/k8s/components/images/dev`: imágenes locales para `dev`.
- `platform/k8s/components/images/staging`: imágenes canónicas de registry para `staging`, promocionadas por digest.
- `platform/k8s/components/images/staging-local`: excepción local con tags mutables `:main` solo para aprendizaje.
- `platform/k8s/overlays/dev`: namespace `atlas-platform-dev`.
- `platform/k8s/overlays/staging`: namespace `atlas-platform-staging`.
- `platform/k8s/overlays/staging-local`: wrapper local del flujo GitOps de `staging`.

## Prerrequisitos

- `mise`
- `kubectl`
- `docker`
- `k3s`
- cluster accesible con `kubectl`
- `IngressClass` activa (Traefik por defecto)
- `metrics-server` recomendado para HPA
- para `staging`: imágenes ya publicadas en GHCR y bootstrap GitOps completado en `argocd`

## Flujo recomendado para dev

```bash
mise install
mise run bootstrap
mise run app-bootstrap
mise run k8s-preflight
mise run k8s-build-images
mise run k8s-import-images
mise run k8s-deploy-dev
mise run k8s-status
mise run k8s-access
```

`mise run k8s-build-images` genera tags locales únicos por ejecución y escribe el
estado en `.gitops-local/k3s/dev-images.env`. Los pasos de importación y despliegue
leen ese archivo para evitar que k3s reutilice una imagen vieja con un tag estático.

Qué hace `mise run k8s-deploy-dev`:

1. ejecuta preflight,
2. limpia el job de migración previo,
3. elimina el `Deployment` legado de PostgreSQL si aún existe,
4. aplica el overlay renderizado con KSOPS y las imágenes locales del build activo,
5. fuerza recreación del pod de PostgreSQL para aplicar cambios del `StatefulSet`,
6. espera a PostgreSQL,
7. recrea el job Alembic,
8. espera backend y frontend,
9. ejecuta smoke checks contra API, frontend e Ingress.

## Flujo recomendado para staging

`staging` ya no es un overlay de `kubectl apply` directo. Su camino operativo es GitOps + registry:

```bash
mise run k8s-doctor
mise run k8s-validate-overlays
mise run gitops-bootstrap-core
mise run gitops-install-age-key
mise run gitops-install-repo-credential
ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
mise run k8s-status-staging
mise run k8s-access-staging
```

En local, `mise run gitops-deploy-staging` hace dos cosas adicionales por defecto:

1. construye `ghcr.io/<owner>/atlas-inventory-service:main` y `ghcr.io/<owner>/atlas-web:main`,
2. las importa en el runtime de k3s y sincroniza Argo CD contra `platform/k8s/overlays/staging-local`.

Ese wrapper mantiene el modelo GitOps de `staging`, pero usa `imagePullPolicy: IfNotPresent`
para que el cluster local pueda arrancar aunque GHCR todavía no tenga publicadas las tags `:main`.
La política endurecida solo aplica al overlay canónico `staging`; `staging-local` existe para no
debilitar el contrato inmutable del camino real de promoción.

Si quieres probar exactamente el camino registry-first del overlay canónico:

```bash
STAGING_LOCAL_IMAGES=0 ARGOCD_APP_REVISION=<remote-branch-or-commit> mise run gitops-deploy-staging
```

`staging` permite validar la reconciliación de Argo CD, el render KSOPS y la topología preproductiva en el cluster local sin mezclarlo con el flujo `dev`.
El path canónico además exige imágenes firmadas: `mise run k8s-validate-overlays` y la promoción
por digest validan Cosign contra `Release Images` en `main`.

## Doctor endurecido

```bash
mise run k8s-doctor
ATLAS_DOCTOR_SCOPE=dev mise run k8s-doctor
```

El doctor ahora falla si faltan prerrequisitos del staging endurecido (Argo CD, age key,
credential del repo, helpers GitOps, render o bundles de política). Para un chequeo local mas
liviano de laboratorio, usa `ATLAS_DOCTOR_SCOPE=dev`.

## Backup y restore de PostgreSQL

Backup:

```bash
mise run k8s-backup-postgres-staging
```

El comando crea un dump `pg_dump -Fc` con timestamp en `.gitops-local/backups/staging/` y te
imprime el comando exacto de restore. Los Jobs efimeros de backup/restore usan la etiqueta
`atlas-postgres-access=true`, que debe permanecer permitida por las `NetworkPolicy` del componente.

Para validar el flujo sin lanzar un dump real:

```bash
ATLAS_POSTGRES_DRY_RUN=1 mise run k8s-backup-postgres-staging
```

Restore:

```bash
BACKUP_FILE=.gitops-local/backups/staging/<timestamp>.dump \
ATLAS_CONFIRM_POSTGRES_RESTORE=atlas-platform-staging \
mise run k8s-restore-postgres-staging
```

Guardrails del restore:

1. exige `BACKUP_FILE` existente,
2. exige el token exacto `ATLAS_CONFIRM_POSTGRES_RESTORE=atlas-platform-staging`,
3. carga el dump en un Job efimero,
4. re-renderiza/aplica el overlay del entorno,
5. espera `inventory-migration` y corre smoke checks antes de reportar exito.

Usa `ATLAS_POSTGRES_DRY_RUN=1` si quieres inspeccionar los pasos sin tocar el cluster.

## Smoke checks

```bash
mise run k8s-smoke
mise run k8s-smoke-staging
```

Los smoke checks validan localmente:

- `/readyz` del backend,
- `GET /api/v1/inventory/products`,
- respuesta HTTP del frontend,
- reachability por Ingress con los hostnames del entorno,
- finalización correcta del job de migración.

## Acceso

### Dev

```bash
mise run k8s-access
```

Hosts esperados:

- `atlas.local`
- `api.atlas.local`

### Staging

```bash
mise run k8s-access-staging
```

Hosts esperados:

- `staging.atlas.example.com`
- `api.staging.atlas.example.com`

`staging` usa HTTPS con el entrypoint `websecure` de Traefik. En k3s local se valida contra el certificado por defecto del ingress controller.

## Logs y operación diaria

### Estado

```bash
mise run k8s-status
mise run k8s-status-staging
kubectl -n atlas-platform-dev get events --sort-by=.lastTimestamp
kubectl -n atlas-platform-staging get events --sort-by=.lastTimestamp
```

### Logs

```bash
kubectl -n atlas-platform-dev logs deploy/inventory-service --tail=200 -f
kubectl -n atlas-platform-dev logs deploy/web --tail=200 -f
kubectl -n atlas-platform-dev logs statefulset/postgres --tail=200 -f
kubectl -n atlas-platform-dev logs job/inventory-migration --tail=200
```

```bash
kubectl -n atlas-platform-staging logs deploy/inventory-service --tail=200 -f
kubectl -n atlas-platform-staging logs deploy/web --tail=200 -f
kubectl -n atlas-platform-staging logs statefulset/postgres --tail=200 -f
kubectl -n atlas-platform-staging logs job/inventory-migration --tail=200
```

### Re-ejecutar migraciones

```bash
kubectl -n atlas-platform-dev delete job inventory-migration --ignore-not-found
./scripts/gitops/render-overlay.sh platform/k8s/overlays/dev | kubectl apply -f -
kubectl -n atlas-platform-dev wait --for=condition=complete job/inventory-migration --timeout=300s
```

## Eliminación de entornos

```bash
mise run k8s-delete-dev
ATLAS_CONFIRM_STAGING_DELETE=atlas-platform-staging mise run k8s-delete-staging
```

`k8s-delete-staging` ahora es GitOps-aware: elimina primero la Application de Argo CD
sin cascada, filtra `Namespace` y `PersistentVolumeClaim` del delete renderizado por defecto y
preserva el almacenamiento. Usa `PRESERVE_POSTGRES_PVC=0` solo para borrar tambien el
almacenamiento y el namespace.

## Alcance

Este runbook endurece el flujo no productivo de `dev` y `staging`. Producción queda fuera del alcance operativo actual del repositorio.

## Troubleshooting rápido

### PostgreSQL no arranca

- revisa `kubectl -n <ns> logs statefulset/postgres`,
- valida permisos del volumen y provisión del PVC,
- confirma secreto `postgres-secret`.

### Job de migración no termina

- revisa `kubectl -n <ns> logs job/inventory-migration`,
- confirma `INVENTORY_DATABASE_URL`,
- confirma conectividad a `postgres:5432`.

### Tráfico bloqueado

- revisa NetworkPolicies activas,
- confirma política DNS,
- confirma reglas hacia PostgreSQL.
