# Desarrollo local

Esta guia concentra el loop diario para desarrollar, validar y depurar Atlas Platform
sin salir del flujo canónico del repositorio.

## Modos de trabajo

### Stack completo con Compose

```bash
mise run compose-up
```

Servicios expuestos:

- Web: `http://localhost:8080`
- API docs: `http://localhost:8000/docs`
- API liveness: `http://localhost:8000/healthz`
- API readiness: `http://localhost:8000/readyz`

Gestion del stack:

```bash
mise run compose-logs
mise run compose-down
```

### Procesos de desarrollo por separado

Backend:

```bash
mise run backend-dev
```

Frontend:

```bash
mise run frontend-dev
```

## Flujo diario recomendado

```bash
git status
mise run fmt
mise run lint
mise run test
mise run check
```

Antes de abrir una PR:

```bash
mise run ci
pre-commit run --all-files
```

## Cuando usar k3s local

Usa k3s cuando necesites validar:

- overlays reales de Kubernetes,
- comportamiento del namespace `atlas-platform-dev`,
- smoke checks y reachability por Ingress,
- el flujo GitOps de `staging` en un cluster local.

Punto de entrada: [Panorama operativo](../operations/overview.md)

## Troubleshooting rapido

- `mise` no se encuentra: inicializa `mise` en tu shell y reinicia terminal.
- `fmt-check` falla por diff: ejecuta `mise run fmt`, revisa cambios y repite.
- fallo de conexion del backend: revisa `INVENTORY_DATABASE_URL` y el estado de PostgreSQL.
