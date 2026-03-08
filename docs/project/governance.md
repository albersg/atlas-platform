# Gobernanza del proyecto

Atlas Platform combina reglas de colaboracion, seguridad y automatizacion para
que el flujo de trabajo sea predecible tanto para humanos como para agentes.

## Documentos de gobierno

- `AGENTS.md`: contrato operativo para sesiones agenticas.
- `CONTRIBUTING.md`: flujo local, requisitos de PR y calidad de commits.
- `SECURITY.md`: canal de reporte y requisitos de desarrollo seguro.
- `.github/CODEOWNERS`: ownership obligatorio para revision.
- `.github/pull_request_template.md`: estructura base de las PRs.

## Reglas de colaboracion

Resumen de `CONTRIBUTING.md`:

- empieza cada cambio con `git status`,
- mantén los cambios pequenos y acotados,
- no bypasses hooks ni CI,
- no incluir datos sensibles en commits,
- ejecuta `mise run check`, `mise run security` y `mise run ci` antes de la PR.

## Reglas para agentes

Resumen de `AGENTS.md`:

- no usar `git commit --no-verify`,
- no ejecutar acciones destructivas sin peticion explicita,
- no tocar credenciales ni material sensible,
- usar `mise run ...` como interfaz operativa principal,
- mantener cambios minimos, reversibles y en alcance.

## Politica de seguridad

Resumen de `SECURITY.md`:

- no abrir issues publicos con detalles de explotacion,
- reportar vulnerabilidades de forma privada a los maintainers,
- incluir impacto, reproduccion y archivos afectados,
- mantener minimo privilegio, escaneo de material sensible y validacion previa al merge.

## Ownership y revision

- al menos un CODEOWNER debe revisar los cambios relevantes,
- los workflows y automatizaciones deben mantenerse fijados por SHA completo,
- cambios con impacto de seguridad deben incluir riesgo y rollback en la PR.

## Referencias en GitHub

- [AGENTS.md](https://github.com/albersg/atlas-platform/blob/main/AGENTS.md)
- [CONTRIBUTING.md](https://github.com/albersg/atlas-platform/blob/main/CONTRIBUTING.md)
- [SECURITY.md](https://github.com/albersg/atlas-platform/blob/main/SECURITY.md)
- [CODEOWNERS](https://github.com/albersg/atlas-platform/blob/main/.github/CODEOWNERS)
