# Desarrollo frontend

`apps/web` contiene la aplicacion frontend del repositorio basada en React, Vite
y TypeScript.

## Tareas principales

```bash
mise run frontend-dev
mise run frontend-build
```

## Uso recomendado

- usa `mise run frontend-dev` para el loop rapido de interfaz,
- combinalo con `mise run backend-dev` si necesitas la API local,
- usa `mise run compose-up` si quieres validar el stack completo sin separar procesos.

## Build de produccion

```bash
mise run frontend-build
```

Util para validar que cambios de UI, imports o configuracion siguen compilando
antes de abrir una PR.

## Observabilidad con Sentry

Variables opcionales del frontend:

- `VITE_SENTRY_DSN`
- `VITE_SENTRY_ENVIRONMENT`
- `VITE_SENTRY_TRACES_SAMPLE_RATE`

## Relacion con el resto del repo

- la app web se sirve en `http://localhost:8080` cuando usas Compose,
- consume el backend `inventory-service`,
- forma parte del mismo flujo de calidad, seguridad y release que el backend.
