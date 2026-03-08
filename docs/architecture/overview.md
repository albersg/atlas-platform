# Resumen de arquitectura

Atlas Platform adopta una arquitectura modular orientada a crecimiento progresivo,
sin forzar una separacion prematura en muchos repositorios o servicios.

## Principios base

- Arquitectura hexagonal dentro de cada servicio.
- Screaming architecture por capacidad de negocio (`inventory`, `billing`).
- Monorepo modular con extraccion futura guiada por ADRs y por necesidad real.
- Contrato operativo compartido entre humanos y agentes.

## Como se organiza el sistema

- `apps/web`: interfaz frontend.
- `services/inventory-service`: servicio backend operativo.
- `services/billing-service`: scaffold preparado para evolucionar.
- `platform/k8s`: recursos compartidos, piezas reutilizables y overlays.
- `platform/argocd`: instalacion y aplicaciones GitOps.

## Modelo de despliegue actual

- local: Docker Compose o procesos locales,
- `dev`: k3s con imagenes locales,
- `staging`: GitOps con Argo CD, SOPS y digests de registry.

La arquitectura se ha recortado de forma deliberada a `dev` y `staging` para no
mezclar responsabilidades no productivas con una futura infraestructura de produccion.

## Lecturas relacionadas

- [Hexagonal + Screaming Architecture](hexagonal-screaming-architecture.md)
- [Deployment Topology](deployment-topology.md)
- [ADR monorepo vs multirepo](../adr/0001-monorepo-vs-multirepo.md)
