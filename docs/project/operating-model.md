# Modelo operativo

Esta guia resume el estado actual del proyecto, el flujo diario recomendado y los
criterios de escalado tecnico y de crecimiento.

## Estado actual

Atlas Platform queda preparado para:

- backend y frontend funcionales,
- primera migracion Alembic para tablas base,
- pipeline de calidad y seguridad coherente en local y CI,
- `dev` sobre k3s con imagenes locales reproducibles,
- `staging` con topologia GitOps y promocion por digest.

## Alcance operativo

El alcance operativo actual dentro de este repositorio es:

- `local` para desarrollo,
- `dev` como laboratorio en k3s,
- `staging` como entorno preproductivo GitOps.

`prod` se difiere intencionadamente hasta disponer de infraestructura separada.

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

## Criterios de escalado del codigo

- mantener bounded contexts claros por servicio,
- evitar acoplar dominio con infraestructura,
- extraer nuevos servicios solo cuando exista presion real de autonomia.

Senales para extraer mas microservicios:

- ownership por equipo claramente separado,
- ciclos de release muy distintos entre dominios,
- poco cambio cross-service,
- necesidad de escalar piezas de forma independiente.

## Criterios de escalado de plataforma

- pasar de Compose a despliegues por entorno con overlays dedicados,
- sustituir valores sensibles inline por un gestor externo,
- reforzar HPA, requests, limites y politicas de red,
- incorporar policy-as-code mas estricta,
- separar observabilidad por servicio.

## Criterios de escalado del repositorio

- estrategia actual: monorepo modular,
- estrategia futura: multirepo solo cuando se cumplan los criterios definidos por la ADR correspondiente.

## Troubleshooting rapido

- `mise` no se encuentra: verifica la activacion de `mise` en tu shell y reinicia terminal.
- `fmt-check` falla en CI o local: ejecuta `mise run fmt`, revisa el diff y repite la validacion.
- error de Alembic por conexion: confirma `INVENTORY_DATABASE_URL` y conectividad a PostgreSQL.
- k3s reutiliza imagenes antiguas en `dev`: reconstruye con `mise run k8s-build-images` y reimporta antes de desplegar.
