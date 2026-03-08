# Documentación de Atlas Platform

Atlas Platform concentra en un mismo repositorio la documentación de desarrollo,
arquitectura, operación y gobierno del proyecto. El objetivo es que cualquier
persona o agente pueda encontrar rápidamente el flujo correcto sin perder
detalle técnico.

## Empieza aquí

- Si es tu primera vez: [Quickstart](getting-started/quickstart.md)
- Si necesitas ubicarte en el repo: [Mapa del repositorio](getting-started/repository-map.md)
- Si quieres implementar una feature: [Flujo end-to-end](development/END_TO_END_WORKFLOW.md)
- Si necesitas operar `dev` o `staging`: [Panorama operativo](operations/overview.md)

## Navegación por tarea

| Necesito... | Documento |
| --- | --- |
| Arrancar el proyecto y validar el entorno | [Quickstart](getting-started/quickstart.md) |
| Entender el loop local diario | [Desarrollo local](development/local-development.md) |
| Trabajar en `inventory-service` y sus migraciones | [Desarrollo backend](development/backend-development.md) |
| Trabajar en `apps/web` | [Desarrollo frontend](development/frontend-development.md) |
| Ejecutar calidad, seguridad y CI local | [Calidad y CI](development/quality-and-ci.md) |
| Revisar los principios de arquitectura | [Resumen de arquitectura](architecture/overview.md) |
| Consultar ADRs del proyecto | [Indice de ADRs](adr/index.md) |
| Operar k3s, Argo CD y promocion por digest | [Operaciones](operations/overview.md) |
| Ver el catálogo de tareas `mise` | [Tareas canónicas](reference/commands.md) |
| Consultar reglas de colaboración y seguridad | [Gobernanza](project/governance.md) |

## Modelo actual de entornos

| Entorno | Uso principal | Modelo |
| --- | --- | --- |
| Local | Desarrollo rápido | Docker Compose o procesos locales |
| `dev` | Laboratorio k3s local | k3s + imágenes locales |
| `staging` | Validación GitOps preproductiva | Argo CD + SOPS + GHCR |

`prod` está fuera del alcance operativo actual del repositorio.

## Camino de validación canónico

```bash
mise run fmt
mise run lint
mise run typecheck
mise run test
mise run docs-build
mise run check
mise run ci
```

## Estructura de la documentación

- Primeros pasos: arranque, entorno y mapa del repo.
- Desarrollo: loops diarios, backend, frontend, calidad y actualización de paquetes.
- Arquitectura: principios, topología y ADRs.
- Operaciones: `dev`, `staging`, k3s, GitOps y promoción de imágenes.
- Referencia: tareas canónicas y estructura técnica.
- Proyecto: gobierno, reglas de colaboración, troubleshooting y modelo operativo.
