# Runbook de Despliegue en k3s

Este documento describe un flujo completo, operativo y robusto para desplegar la plataforma en k3s.

## 1. Alcance

El runbook cubre:

- preparación del cluster,
- build e import de imágenes locales,
- despliegue de backend, frontend y base de datos,
- ejecución de migraciones Alembic,
- validación post-despliegue,
- acceso al sistema,
- operación diaria y troubleshooting.

## 2. Componentes desplegados

En `platform/k8s/base` se despliegan:

- recursos namespaced comunes reutilizados por `dev` y `prod`.
- `config/`: ConfigMaps y Secrets.
- `data/`: almacenamiento persistente.
- `workloads/`: Deployments y Jobs.
- `networking/`: Services e Ingress.
- `resilience/`: HPA y PDB.

- `Namespace` dev: `atlas-platform-dev`.
- `Namespace` prod: `atlas-platform-prod`.
- `Secret` de PostgreSQL: `postgres-secret`.
- `Secret` de backend: `inventory-secrets`.
- `ConfigMap` de backend: `inventory-config`.
- `PVC` de PostgreSQL: `postgres-pvc`.
- `Deployment` PostgreSQL: `postgres`.
- `Service` PostgreSQL: `postgres`.
- `Job` de migración: `inventory-migration`.
- `Deployment` backend: `inventory-service`.
- `Service` backend: `inventory-service`.
- `Deployment` frontend: `web`.
- `Service` frontend: `web`.
- `Ingress`: `atlas-ingress`.
- `PDB`: `inventory-service-pdb`, `web-pdb`, `postgres-pdb`.
- `HPA`: `inventory-service`, `web`.
- `NetworkPolicy`: deny-by-default con reglas explícitas para DNS, web, API y PostgreSQL.

Overlays:

- `platform/k8s/overlays/dev`: entorno local con imágenes `atlas-*:dev`.
- `platform/k8s/overlays/prod`: entorno productivo (hosts de ejemplo).

## 3. Prerrequisitos

## 3.1 Herramientas

- `mise`
- `kubectl`
- `docker`
- `k3s`

Nota: `mise` gestiona el flujo del repo; `kubectl/docker/k3s` dependen del host.

## 3.2 Cluster

- k3s levantado y accesible con `kubectl`.
- Ingress controller disponible (por defecto, Traefik en k3s).
- Recomendado: `metrics-server` activo para HPA por CPU.

## 4. Flujo de despliegue dev (recomendado)

## 4.1 Preparar entorno de trabajo

```bash
mise install
mise run bootstrap
mise run app-bootstrap
```

## 4.2 Verificar cluster

```bash
mise run k8s-preflight
```

Valida:

- conectividad del cluster,
- presencia de `IngressClass traefik`,
- presencia de `metrics-server`.

## 4.3 Construir imágenes locales

```bash
mise run k8s-build-images
```

Tags generados:

- `atlas-inventory-service:dev`
- `atlas-web:dev`

## 4.4 Importar imágenes a k3s

```bash
mise run k8s-import-images
```

Este paso exporta con `docker save` e importa con `sudo k3s ctr images import`.

## 4.5 Desplegar overlay dev

```bash
mise run k8s-deploy-dev
```

Este comando:

1. valida preflight,
2. elimina job anterior de migración,
3. aplica `platform/k8s/overlays/dev`,
4. espera rollout de PostgreSQL,
5. espera finalización del job Alembic,
6. espera rollout de backend y frontend.

## 5. Acceso tras desplegar

## 5.1 Hostnames

Obtén ayuda automática:

```bash
mise run k8s-access
```

El comando muestra:

- IP del nodo,
- línea sugerida para `/etc/hosts`,
- URLs objetivo.

Entradas típicas:

```text
<NODE_IP> atlas.local api.atlas.local
```

## 5.2 URLs

- Frontend: `http://atlas.local`
- API docs: `http://api.atlas.local/docs`
- Health API: `http://api.atlas.local/healthz`

## 5.3 Fallback con port-forward

Si Ingress no está disponible:

```bash
kubectl -n atlas-platform-dev port-forward svc/web 8080:80
kubectl -n atlas-platform-dev port-forward svc/inventory-service 8000:8000
```

Accesos fallback:

- Frontend: `http://localhost:8080`
- API docs: `http://localhost:8000/docs`

## 6. Seguridad y hardening aplicados

- Namespace con labels de Pod Security `baseline`.
- Secrets separados para DB y backend.
- Alembic fuera del startup path principal mediante `Job` dedicado.
- `RUN_MIGRATIONS_ON_STARTUP=0` en despliegue k8s.
- Probes (`startup`, `readiness`, `liveness`) en backend y frontend.
- Requests/limits en backend, frontend, job y PostgreSQL.
- `allowPrivilegeEscalation: false` y `capabilities.drop: [ALL]` en workloads de app.
- `seccompProfile: RuntimeDefault` en workloads de app y PostgreSQL.
- `automountServiceAccountToken: false` en deployments y job.
- PDB para backend/frontend/PostgreSQL.
- HPA para backend/frontend.
- NetworkPolicies para reducir tráfico lateral y permitir solo flujos necesarios.

## 7. Operación diaria

## 7.1 Estado y salud

```bash
mise run k8s-status
kubectl -n atlas-platform-dev get events --sort-by=.lastTimestamp
```

## 7.2 Logs

```bash
kubectl -n atlas-platform-dev logs deploy/inventory-service --tail=200 -f
kubectl -n atlas-platform-dev logs deploy/web --tail=200 -f
kubectl -n atlas-platform-dev logs deploy/postgres --tail=200 -f
kubectl -n atlas-platform-dev logs job/inventory-migration --tail=200
```

## 7.3 Re-ejecutar migraciones

```bash
kubectl -n atlas-platform-dev delete job inventory-migration --ignore-not-found
kubectl apply -k platform/k8s/overlays/dev
kubectl -n atlas-platform-dev wait --for=condition=complete job/inventory-migration --timeout=300s
```

## 7.4 Eliminar entorno dev

```bash
mise run k8s-delete-dev
```

## 8. Paso a producción

## 8.1 Overlay prod

Base:

- `platform/k8s/overlays/prod/kustomization.yaml`

Ajustes mínimos antes de usarlo:

1. actualizar hosts reales del Ingress,
2. usar imágenes de registry real (no tags `dev`),
3. rotar secretos con valores reales,
4. revisar requests/limits según carga,
5. activar TLS con `cert-manager` (recomendado).

## 8.2 Flujo sugerido prod

1. Build/push imágenes versionadas (`x.y.z` o SHA).
2. Parchar tags en overlay prod.
3. Aplicar overlay prod.
4. Esperar migración + rollout.
5. Ejecutar checks de humo (`/healthz`, `/docs`, flujo UI).

## 9. Gestión de secretos

En base se incluyen placeholders para demo.

Antes de producción:

- reemplaza `change-me-in-prod` por secretos reales,
- idealmente migra a gestor externo (External Secrets, Vault, SOPS, Sealed Secrets),
- evita secretos en texto plano en git.

## 10. Troubleshooting rápido

## 10.1 Pod en CrashLoopBackOff

- revisa logs del workload,
- revisa disponibilidad de PostgreSQL,
- revisa valor de `INVENTORY_DATABASE_URL`.

## 10.2 Job de migración no completa

- `kubectl -n atlas-platform-dev logs job/inventory-migration`
- comprobar credenciales y conectividad a `postgres:5432`.

## 10.3 Ingress sin respuesta

- verificar `IngressClass` activa,
- verificar host en `/etc/hosts`,
- fallback con `port-forward`.

## 10.4 HPA sin escalar

- comprobar `metrics-server` en `kube-system`,
- comprobar requests CPU definidos en deployments.

## 10.5 Tráfico bloqueado entre pods

- revisar NetworkPolicies activas: `kubectl -n atlas-platform get networkpolicy`,
- validar reglas DNS/CoreDNS (`kube-system`, `k8s-app=kube-dns`),
- confirmar que backend puede llegar a `postgres:5432`.

## 11. Comandos de referencia

```bash
mise run k8s-preflight
mise run k8s-build-images
mise run k8s-import-images
mise run k8s-deploy-dev
mise run k8s-status
mise run k8s-access
mise run k8s-delete-dev
```
