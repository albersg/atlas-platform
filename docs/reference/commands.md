# Tareas canónicas

`mise.toml` es la fuente de verdad del toolchain y del catalogo de tareas del proyecto.
Esta pagina agrupa esas tareas por objetivo para que la navegacion sea mas rapida.

## Setup y mantenimiento del entorno

- `mise run doctor`: diagnostico de `mise` mas readiness endurecida de Kubernetes/GitOps del repo.
- `mise run k8s-doctor`: falla si faltan prerequisitos del staging endurecido y valida render + bundles de politica; usa `ATLAS_DOCTOR_SCOPE=dev` para un chequeo mas liviano.
- `mise run bootstrap`: instala hooks de git.
- `mise run app-bootstrap`: instala paquetes de backend y frontend.
- `mise run hooks-update`: actualiza hooks de `pre-commit`.
- `mise run lock`: actualiza `mise.lock`.

## Calidad, seguridad y docs

- `mise run fmt`: auto-fixes de formato.
- `mise run fmt-check`: verifica que `fmt` no deje diffs.
- `mise run lint`: lint y policy checks con reintentos controlados.
- `mise run security`: checks de seguridad dedicados.
- `mise run test`: tests de politica del repo y unit tests backend.
- `mise run backend-test-cov`: tests backend con cobertura.
- `mise run backend-typecheck`: type checking del backend.
- `mise run typecheck`: agrupador de type checks.
- `mise run docs-build`: build estricto de documentacion.
- `mise run docs-serve`: servidor local de docs.
- `mise run check`: validacion local completa.
- `mise run fix`: alias de `fmt`.
- `mise run ci`: camino equivalente a CI.

## Desarrollo de aplicacion

- `mise run backend-dev`: levanta `inventory-service`.
- `mise run backend-migrate`: aplica migraciones Alembic.
- `mise run backend-test`: ejecuta tests del servicio.
- `mise run frontend-dev`: levanta la app web.
- `mise run frontend-build`: genera build del frontend.
- `mise run compose-up`: arranca el stack local con Docker Compose.
- `mise run compose-down`: detiene el stack local.
- `mise run compose-logs`: muestra logs del stack.

## k3s y flujos de cluster

- `mise run k8s-preflight`: valida prerequisitos del cluster.
- `mise run k8s-build-images`: construye imagenes locales para `dev`.
- `mise run k8s-import-images`: importa esas imagenes a k3s.
- `mise run k8s-build-staging-images`: construye refs locales para `staging-local`.
- `mise run k8s-import-staging-images`: importa refs locales para `staging-local` en k3s.
- `mise run k8s-deploy-dev`: despliega `dev` y ejecuta smoke checks.
- `mise run k8s-smoke`: smoke checks contra `atlas-platform-dev`.
- `mise run k8s-smoke-staging`: smoke checks contra `atlas-platform-staging`.
- `mise run k8s-status`: estado de workloads, services e ingress de `dev`.
- `mise run k8s-status-staging`: estado de `staging`.
- `mise run k8s-access`: URLs y host mapping de `dev`.
- `mise run k8s-access-staging`: URLs y host mapping de `staging`.
- `mise run k8s-delete-dev`: elimina recursos del overlay `dev`.
- `mise run k8s-delete-staging`: teardown GitOps-aware de `staging`; exige `ATLAS_CONFIRM_STAGING_DELETE=atlas-platform-staging`, elimina la `Application` sin cascada y filtra `Namespace` + `PersistentVolumeClaim` del delete por defecto salvo `PRESERVE_POSTGRES_PVC=0`.
- `mise run k8s-backup-postgres-staging`: crea un dump timestamped en `.gitops-local/backups/staging/`, devuelve el commando exacto de restore y admite `ATLAS_POSTGRES_DRY_RUN=1` para validar el flujo sin correr el job real.
- `mise run k8s-restore-postgres-staging`: restaura desde `BACKUP_FILE=...` con confirmation explicita `ATLAS_CONFIRM_POSTGRES_RESTORE=atlas-platform-staging`.
- `mise run k8s-validate-overlays`: renderiza `dev`, `staging` y `staging-local`; aplica politicas comunes y refuerzos solo a `staging` canonico.
- `mise run policy-check`: alias de validacion overlay-aware para manifests no productivos.

## GitOps y Argo CD

- `mise run gitops-install-tools`: instala binaries auxiliares.
- `mise run gitops-bootstrap-core`: instala Argo CD core y plugin KSOPS.
- `mise run gitops-install-age-key`: instala la clave age en `argocd`.
- `mise run gitops-install-repo-credential`: instala la credential del repositorio.
- `mise run gitops-apply-apps`: aplica el bundle GitOps de staging.
- `mise run gitops-apply-staging`: aplica solo la app de `staging`.
- `mise run gitops-wait-staging`: espera a que la app de `staging` sincronice.
- `mise run gitops-deploy-staging`: despliega `staging-local` por defecto en k3s y deja `staging` canonico para el camino registry+digest+firma verificada.
- `mise run gitops-render-dev`: render local del overlay `dev`.
- `mise run gitops-render-staging`: render local del overlay `staging`.

## Donde ampliar informacion

- [Calidad y CI](../development/quality-and-ci.md)
- [Panorama operativo](../operations/overview.md)
- [Runbook k3s](../deployment/k3s/RUNBOOK.md)
- [Runbook GitOps](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md)
