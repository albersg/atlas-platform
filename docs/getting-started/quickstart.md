# Quickstart

Esta guia resume el arranque minimo para dejar Atlas Platform listo para trabajar
en local con un flujo reproducible.

## Prerrequisitos

El repositorio parte de que las herramientas base ya estan instaladas en tu maquina.

- `mise`
- `git`
- `docker` para el loop con Compose
- `kubectl` y `k3s` si vas a trabajar con `dev` o `staging` en cluster local

## Bootstrap de arranque

```bash
mise install
mise run bootstrap
mise run app-bootstrap
```

Que hace cada paso:

- `mise install`: instala el toolchain fijado en `mise.toml`.
- `mise run bootstrap`: instala hooks de `pre-commit` y `pre-push`.
- `mise run app-bootstrap`: sincroniza paquetes de backend y frontend.

## Primera validacion recomendada

```bash
mise run check
mise run docs-build
```

Con esto verificas que el repositorio, el backend tipado/tests y la documentacion
estan sanos en tu entorno.

## Elige tu primer loop de trabajo

### Stack completo con Docker Compose

```bash
mise run compose-up
```

Endpoints utiles:

- Web: `http://localhost:8080`
- API docs: `http://localhost:8000/docs`
- API liveness: `http://localhost:8000/healthz`
- API readiness: `http://localhost:8000/readyz`

Gestion del stack:

```bash
mise run compose-logs
mise run compose-down
```

### Backend solo

```bash
mise run backend-dev
```

### Frontend solo

```bash
mise run frontend-dev
```

## Siguientes lecturas recomendadas

- [Mapa del repositorio](repository-map.md)
- [Desarrollo local](../development/local-development.md)
- [Desarrollo backend](../development/backend-development.md)
- [Desarrollo frontend](../development/frontend-development.md)
- [Panorama operativo](../operations/overview.md)
