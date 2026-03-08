# Mapa del repositorio

Esta pagina sirve como indice rapido de donde vive cada responsabilidad tecnica
dentro de Atlas Platform.

## Vista general

```text
.
├── apps/
├── services/
├── platform/
├── scripts/
├── docs/
├── tests/
├── mise.toml
└── .pre-commit-config.yaml
```

## Aplicacion

- `apps/web`: frontend React + Vite + TypeScript.
- `services/inventory-service`: backend principal con FastAPI, SQLAlchemy y Alembic.
- `services/billing-service`: scaffold del siguiente bounded context.

## Plataforma

- `platform/k8s`: recursos base, piezas reutilizables y overlays por entorno.
- `platform/argocd`: instalacion de Argo CD y aplicaciones GitOps.
- `platform/policy`: policy-as-code para overlays de entornos no productivos.

## Automatizacion operativa

- `scripts/k3s`: preflight, build/import de imagenes, accesos y despliegues en k3s.
- `scripts/gitops`: bootstrap, render, espera y despliegue GitOps.
- `scripts/release`: helpers para promocion de imagenes por digest.

## Calidad, seguridad y gobierno

- `mise.toml`: fuente de verdad del toolchain y de las tareas `mise run`.
- `mise.lock`: metadata de lock para instalaciones reproducibles.
- `.pre-commit-config.yaml`: hooks de formato, lint y seguridad.
- `.github/workflows/`: CI, seguridad, CodeQL, release y promocion.
- `.github/CODEOWNERS`: ownership obligatorio para revision.
- `tests/`: pruebas de politica del repositorio.
- `AGENTS.md`, `CONTRIBUTING.md`, `SECURITY.md`: reglas operativas y de colaboracion.

## Documentacion

- `docs/getting-started`: arranque y orientacion del proyecto.
- `docs/development`: guias de trabajo diario.
- `docs/architecture`: principios, topologia y patrones.
- `docs/adr`: ADRs y decisiones arquitectonicas.
- `docs/operations`: vistas operativas y runbooks.
- `docs/reference`: catalogos y mapas tecnicos.
- `docs/project`: gobierno y modelo operativo.

## Donde tocar segun el tipo de cambio

| Tipo de cambio | Zona principal |
| --- | --- |
| UI o experiencia web | `apps/web` |
| API, dominio o persistencia | `services/inventory-service` |
| Nuevo bounded context | `services/<nuevo-servicio>` |
| Despliegue Kubernetes | `platform/k8s` |
| GitOps / Argo CD | `platform/argocd` y `scripts/gitops` |
| Operacion k3s | `scripts/k3s` |
| CI, seguridad o automatizacion | `.github/workflows`, `mise.toml`, `.pre-commit-config.yaml` |
| Documentacion | `README.md` y `docs/` |
