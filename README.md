# Atlas Platform Monorepo

Plantilla de plataforma "agent-first" orientada a producción, con backend, frontend, base de datos, CI/CD y guardrails DevSecOps para trabajar de forma consistente y escalable.

## Objetivo del repositorio

Este repositorio está diseñado para:

- acelerar desarrollo con comandos canónicos estables (`mise run`),
- unificar tooling y versiones (`mise`),
- forzar calidad y seguridad en local y CI (`pre-commit` + GitHub Actions),
- mantener arquitectura preparada para crecer a microservicios (hexagonal + screaming),
- permitir que agentes y humanos trabajen con el mismo flujo operativo.

## Stack tecnológico

- Backend: Python 3.12 + FastAPI + SQLAlchemy + Alembic (`services/inventory-service`).
- Frontend: React + Vite + TypeScript (`apps/web`).
- Base de datos: PostgreSQL.
- Orquestación local: Docker Compose.
- Orquestación cluster: Kubernetes/k3s con Kustomize (`platform/k8s`).
- Calidad y testing: `ruff`, `pyright`, `pytest`, `pytest-cov`.
- Observabilidad de errores: `sentry-sdk` (opcional vía DSN).
- Documentación: `mkdocs-material`.
- Dependency management remoto: `Dependabot`.
- Escaneo de credenciales expuestas: `gitleaks` + `detect-secrets`.
- Escaneo de contenedores: `Trivy` en pipeline de seguridad.
- SAST remoto: `CodeQL` (ejecución automática en repos públicos).
- Developer platform: `mise`, `pre-commit`.
- CI remoto: GitHub Actions.

## Principios de arquitectura

- Arquitectura hexagonal dentro de cada servicio.
- Screaming architecture por capacidad de negocio (`inventory`, `billing`) antes que por framework.
- Monorepo modular con decisión arquitectónica explícita para futura extracción.

Documentación de referencia:

- [ADR monorepo vs multirepo](docs/adr/0001-monorepo-vs-multirepo.md)
- [Blueprint hexagonal + screaming](docs/architecture/hexagonal-screaming-architecture.md)
- [Topología de despliegue](docs/architecture/deployment-topology.md)
- [Actualización automática de dependencias](docs/development/DEPENDENCY_UPDATES.md)
- [Flujo end-to-end de desarrollo](docs/development/END_TO_END_WORKFLOW.md)
- [Runbook de despliegue k3s](docs/deployment/K3S_DEPLOYMENT_RUNBOOK.md)
- [Contrato operativo de agentes](AGENTS.md)

## Estructura del repositorio

```text
.
├── apps/
│   └── web/                      # Frontend React/Vite
├── services/
│   ├── inventory-service/        # Backend funcional (FastAPI + Alembic)
│   └── billing-service/          # Scaffold para siguiente bounded context
├── platform/
│   └── k8s/                      # Manifiestos base + overlays
├── scripts/
│   └── k3s/                      # Scripts operativos para despliegue en k3s
├── docs/
│   ├── adr/
│   ├── architecture/
│   └── deployment/
├── tests/                        # Tests de política del repositorio
├── mise.toml                     # Fuente de verdad de tools + tasks
└── .pre-commit-config.yaml       # Hooks de calidad/seguridad
```

## Flujo 1: preparación inicial

Este repositorio asume que instalas tú las herramientas base en tu máquina. Una vez instaladas:

```bash
mise install
mise run bootstrap
```

Qué hace:

- instala/activa herramientas definidas en `mise.toml`,
- instala hooks de git (`pre-commit` y `pre-push`).

Después instala dependencias de aplicación:

```bash
mise run app-bootstrap
```

Qué hace:

- backend: `uv sync --extra dev` en `services/inventory-service`,
- frontend: `npm install` en `apps/web`.

## Flujo 2: desarrollo local de extremo a extremo

Levantar stack completo:

```bash
mise run compose-up
```

Endpoints locales:

- Web: `http://localhost:8080`
- API docs: `http://localhost:8000/docs`
- Health check API: `http://localhost:8000/healthz`

Ver logs:

```bash
mise run compose-logs
```

Parar stack:

```bash
mise run compose-down
```

## Flujo 3: desarrollo backend

Arranque en modo desarrollo:

```bash
mise run backend-dev
```

Tests del servicio:

```bash
mise run backend-test
```

Endpoints actuales de `inventory-service`:

- `GET /healthz`
- `GET /api/v1/inventory/products`
- `POST /api/v1/inventory/products`
- `GET /api/v1/inventory/products/{product_id}`

## Flujo 4: migraciones con Alembic

Alembic está integrado y es el mecanismo oficial para cambios de esquema.

Ruta de migraciones:

- `services/inventory-service/alembic/versions/`

Primera revisión creada:

- `services/inventory-service/alembic/versions/20260306_0001_create_products_table.py`

Aplicar migraciones:

```bash
mise run backend-migrate
```

Crear una nueva revisión manualmente:

```bash
cd services/inventory-service
uv run --extra dev alembic revision -m "describe-tu-cambio"
```

Comprobar SQL generado sin ejecutar (útil para revisión):

```bash
cd services/inventory-service
uv run --extra dev alembic upgrade head --sql
```

Regla recomendada:

- todo cambio en modelos persistentes debe ir acompañado de migración Alembic explícita.

## Flujo 5: desarrollo frontend

Servidor de desarrollo:

```bash
mise run frontend-dev
```

Build de producción:

```bash
mise run frontend-build
```

## Observabilidad (Sentry)

Backend (`inventory-service`) usa Sentry si se define:

- `INVENTORY_SENTRY_DSN`
- `INVENTORY_SENTRY_TRACES_SAMPLE_RATE` (ejemplo `0.1`)

Frontend (`apps/web`) usa Sentry si se define:

- `VITE_SENTRY_DSN`
- `VITE_SENTRY_ENVIRONMENT` (opcional)
- `VITE_SENTRY_TRACES_SAMPLE_RATE` (ejemplo `0.1`)

## Flujo 6: despliegue en k3s (dev)

Comprobación de prerequisitos del cluster:

```bash
mise run k8s-preflight
```

Construcción de imágenes locales:

```bash
mise run k8s-build-images
```

Importación de imágenes al runtime de k3s:

```bash
mise run k8s-import-images
```

Despliegue completo y espera activa hasta estado saludable:

```bash
mise run k8s-deploy-dev
```

Estado del despliegue:

```bash
mise run k8s-status
```

Información de acceso:

```bash
mise run k8s-access
```

Eliminación del overlay dev:

```bash
mise run k8s-delete-dev
```

## Comandos canónicos de calidad

Estos son los comandos de referencia del proyecto:

```bash
mise run fmt
mise run lint
mise run typecheck
mise run test
mise run docs-build
mise run check
mise run fix
mise run ci
```

Semántica:

- `mise run fmt`: aplica auto-fixes seguros de formato.
- `mise run lint`: validaciones con reintentos automáticos ante hooks que auto-modifican archivos.
- `mise run lint` usa `MISE_LINT_MAX_TRIES` (por defecto `3`) para limitar reintentos.
- `mise run typecheck`: análisis de tipos (`pyright`) para backend.
- `mise run test`: tests de políticas del repo + tests backend con cobertura.
- `mise run docs-build`: build estricto de documentación con MkDocs Material.
- `mise run check`: validación local completa (`lint + typecheck + test`).
- `mise run fix`: alias de auto-fixes seguros.
- `mise run ci`: camino equivalente a CI (`fmt-check + check + docs-build + security`).

Comando extra recomendado antes de PR:

```bash
pre-commit run --all-files
```

## CI/CD: cómo funciona en GitHub Actions

Workflow principal:

- `.github/workflows/ci.yml`

Qué ejecuta en `push` a `main` y en `pull_request`:

- checkout,
- setup de `mise`,
- `mise run bootstrap`,
- `mise run ci`.

Esto garantiza que lo que pasa en local con los comandos canónicos es lo mismo que se valida en remoto.

## Seguridad y gobernanza

Guardrails activos:

- hooks de baseline (`yaml/json/toml`, merge-conflict, keys, etc.),
- `detect-secrets`,
- `actionlint` + `check-github-workflows`,
- `ruff` para Python,
- `yamllint`, `markdownlint`, `typos`,
- workflow de seguridad dedicado en `.github/workflows/security.yml`,
- `gitleaks` en `pre-commit` y en el task `mise run security`,
- Trivy para escaneo de imágenes de `inventory-service` y `web`,
- CodeQL para análisis estático en entornos compatibles,
- Dependabot para actualizaciones de dependencias (`.github/dependabot.yml`).

Documentos de gobierno:

- [AGENTS.md](AGENTS.md): contrato operativo para agentes.
- [CONTRIBUTING.md](CONTRIBUTING.md): reglas de colaboración.
- [SECURITY.md](SECURITY.md): proceso de seguridad.
- `.github/CODEOWNERS`: ownership y revisión.

## Escalado del proyecto (técnico y organizativo)

### Escalado de código

- mantener bounded contexts claros por servicio,
- evitar acoplar dominio con infraestructura,
- extraer nuevos servicios solo cuando exista presión real de autonomía.

Señales para extraer a más microservicios:

- ownership por equipo claramente separado,
- ciclos de release muy distintos entre dominios,
- bajo volumen de cambios cross-service,
- necesidad de escalar componentes de forma independiente.

### Escalado de plataforma

- pasar de Compose a despliegues por entorno con overlays dedicados,
- sustituir secretos inline por gestor de secretos externo,
- añadir HPA/requests/limits y políticas de red,
- incorporar policy-as-code (Kyverno/OPA),
- separar observabilidad (logs, métricas, trazas) por servicio.

### Escalado de repositorio

Estrategia actual: monorepo modular.
Estrategia futura: multirepo solo cuando los criterios del ADR se cumplan.

## Flujo diario recomendado

```bash
git status
mise run fmt
mise run lint
mise run test
mise run check
```

Antes de abrir PR:

```bash
mise run ci
pre-commit run --all-files
```

## Solución de problemas rápida

- `mise` no se encuentra:
  - verifica que `mise` esté inicializado en tu shell y reinicia terminal.
- `mise run ci` falla en `fmt-check`:
  - ejecuta `mise run fmt`, revisa diff, añade cambios y repite.
- error en Alembic por conexión:
  - confirma `INVENTORY_DATABASE_URL` y conectividad a PostgreSQL.

## Estado actual

El repositorio queda listo para desarrollo "agent-first" con:

- backend y frontend funcionales,
- migración inicial Alembic para tablas base,
- pipeline de calidad/seguridad local y CI coherente,
- base arquitectónica preparada para evolucionar a microservicios.
