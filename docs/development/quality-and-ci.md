# Calidad y CI

Atlas Platform mantiene un camino de validacion unico para local y remoto. La idea
es que desarrolladores y agentes ejecuten las mismas tareas que despues validan
los workflows de GitHub Actions.

## Flujo canonico

| Tarea | Objetivo |
| --- | --- |
| `mise run fmt` | Aplica auto-fixes seguros de formato |
| `mise run lint` | Ejecuta lint y policy checks con reintentos acotados |
| `mise run typecheck` | Ejecuta analisis de tipos del backend |
| `mise run test` | Ejecuta tests de politica del repo y tests unitarios backend |
| `mise run docs-build` | Construye la documentacion con MkDocs Material |
| `mise run security` | Ejecuta checks de seguridad dedicados |
| `mise run check` | Ejecuta `lint + typecheck + test` |
| `mise run ci` | Reproduce el camino de CI: formato, validacion, docs y seguridad |

Tareas de apoyo:

- `mise run fmt-check`: verifica que `fmt` no genere diffs.
- `mise run fix`: alias de auto-fixes seguros.
- `mise run doctor`: diagnostico de entorno `mise`.
- `mise run lock`: actualiza `mise.lock`.
- `mise run hooks-update`: actualiza hooks de `pre-commit`.

## Semantica operativa clave

- `mise run lint` usa `MISE_LINT_MAX_TRIES` y por defecto reintenta hasta `3` veces si algun hook auto-modifica archivos.
- `mise run test` mantiene cobertura para el backend y tests de politica del repo.
- `mise run ci` es la referencia antes de abrir PR cuando quieres aproximarte al camino remoto completo.

## Que ejecuta GitHub Actions

Workflow principal:

- `.github/workflows/ci.yml`

En `push` a `main` y en `pull_request` ejecuta:

- checkout endurecido,
- setup de `mise`,
- `mise run bootstrap`,
- `mise run fmt-check`,
- `mise run check`,
- `mise run docs-build`,
- `mise run security`,
- validacion GitOps de overlays cuando hay `SOPS_AGE_KEY` disponible.

Workflows complementarios:

- `.github/workflows/security.yml`: checks dedicados y Trivy sobre imagenes.
- `.github/workflows/codeql.yml`: analisis SAST con CodeQL.
- `.github/workflows/release-images.yml`: build, scan, firma y publicacion de imagenes.
- `.github/workflows/promote-staging.yml`: promocion de `staging` por digest.

## Guardrails activos

- hooks baseline para YAML/JSON/TOML, conflictos de merge y permisos,
- `detect-secrets` y `gitleaks`,
- `actionlint` y validacion de workflows,
- `ruff`, `yamllint`, `markdownlint` y `typos`,
- Trivy para imagenes de `inventory-service` y `web`,
- CodeQL y politica de paquetes en GitHub.

## Recomendacion antes de PR

```bash
mise run ci
pre-commit run --all-files
```

## Troubleshooting frecuente

- Si `fmt-check` falla por un diff, ejecuta `mise run fmt`, revisa cambios y vuelve a correr `mise run ci`.
- Si un hook falla tras actualizar tooling, ejecuta `mise run bootstrap` para reinstalar hooks.
- Si modificas `mise.toml`, actualiza tambien `mise.lock` con `mise run lock`.
