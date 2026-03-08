# Tareas canónicas

`mise.toml` es la fuente de verdad del toolchain y del catalogo de tareas del proyecto.
Esta pagina agrupa esas tareas por objetivo para que la navegacion sea mas rapida.

## Setup y mantenimiento del entorno

- `mise run doctor`: diagnostico del entorno `mise`.
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
- `mise run k8s-build-staging-images`: construye refs locales de `staging`.
- `mise run k8s-import-staging-images`: importa refs locales de `staging` en k3s.
- `mise run k8s-deploy-dev`: despliega `dev` y ejecuta smoke checks.
- `mise run k8s-smoke`: smoke checks contra `atlas-platform-dev`.
- `mise run k8s-smoke-staging`: smoke checks contra `atlas-platform-staging`.
- `mise run k8s-status`: estado de workloads, services e ingress de `dev`.
- `mise run k8s-status-staging`: estado de `staging`.
- `mise run k8s-access`: URLs y host mapping de `dev`.
- `mise run k8s-access-staging`: URLs y host mapping de `staging`.
- `mise run k8s-delete-dev`: elimina recursos del overlay `dev`.
- `mise run k8s-delete-staging`: elimina recursos del overlay `staging`.
- `mise run k8s-validate-overlays`: renderiza y valida overlays cifrados.
- `mise run policy-check`: valida politicas sobre overlays renderizados.

## GitOps y Argo CD

- `mise run gitops-install-tools`: instala binaries auxiliares.
- `mise run gitops-bootstrap-core`: instala Argo CD core y plugin KSOPS.
- `mise run gitops-install-age-key`: instala la clave age en `argocd`.
- `mise run gitops-install-repo-credential`: instala la credential del repositorio.
- `mise run gitops-apply-apps`: aplica el bundle GitOps de staging.
- `mise run gitops-apply-staging`: aplica solo la app de `staging`.
- `mise run gitops-wait-staging`: espera a que la app de `staging` sincronice.
- `mise run gitops-deploy-staging`: despliega `staging` y ejecuta smoke checks.
- `mise run gitops-render-dev`: render local del overlay `dev`.
- `mise run gitops-render-staging`: render local del overlay `staging`.

## Donde ampliar informacion

- [Calidad y CI](../development/quality-and-ci.md)
- [Panorama operativo](../operations/overview.md)
- [Runbook k3s](../deployment/k3s/RUNBOOK.md)
- [Runbook GitOps](../deployment/gitops/ARGOCD_SOPS_RUNBOOK.md)
