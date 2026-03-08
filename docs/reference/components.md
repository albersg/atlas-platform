# Mapa del monorepo

Esta pagina resume que existe hoy en el monorepo y como se reparte la responsabilidad
entre aplicacion, plataforma y automatizacion.

## Aplicaciones y servicios

### `apps/web`

- frontend React + Vite + TypeScript,
- se ejecuta con `mise run frontend-dev`,
- participa en Compose, en imagenes OCI y en el flujo de release.

### `services/inventory-service`

- servicio backend operativo del repositorio,
- usa FastAPI, SQLAlchemy y Alembic,
- expone health checks y endpoints de products,
- mantiene type checking y tests propios.

Referencia: `services/inventory-service/README.md`

### `services/billing-service`

- scaffold para un futuro bounded context,
- pensado para invoice generation, payment intent orchestration y billing event outbox,
- conserva la misma base hexagonal + screaming que el resto del dominio.

Referencia: `services/billing-service/README.md`

## Plataforma

### `platform/k8s`

- `base/`: recursos compartidos por entorno,
- `components/`: bloques reutilizables,
- `overlays/dev`: laboratorio local con imagenes locales,
- `overlays/staging`: overlay preproductivo respaldado por registry,
- `overlays/staging-local`: wrapper local para validar el flujo GitOps de `staging`.

### `platform/argocd`

- `core/`: instalacion de Argo CD y plugin KSOPS,
- `apps/`: bundle GitOps de `staging`.

Referencia: `platform/argocd/README.md`

## Scripts operativos

### `scripts/k3s`

- `cluster/`: preflight, estado y acceso,
- `images/`: build/import de imagenes,
- `deploy/`: orquestacion de despliegue,
- `verify/`: smoke checks.

Referencia: `scripts/k3s/README.md`

### `scripts/gitops`

- bootstrap de Argo CD,
- render de overlays cifrados,
- espera y despliegue de aplicaciones,
- validacion de overlays y politicas.

### `scripts/release`

- helpers para promocion por digest,
- soporte a workflows de release y promocion.

## Documentos raices importantes

- `README.md`: landing page ejecutiva del repositorio.
- `AGENTS.md`: contrato operativo para agentes.
- `CONTRIBUTING.md`: reglas de colaboracion.
- `SECURITY.md`: politica de seguridad.
- `mise.toml`: mapa operativo de herramientas y tareas.
