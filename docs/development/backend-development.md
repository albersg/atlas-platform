# Desarrollo backend

`inventory-service` es el servicio backend activo del repositorio y sigue una
arquitectura hexagonal + screaming por capacidad de negocio.

## Tareas principales

```bash
mise run backend-dev
mise run backend-test
mise run backend-migrate
mise run typecheck
```

Tambien puedes ejecutar la suite con cobertura:

```bash
mise run backend-test-cov
```

## Endpoints actuales de `inventory-service`

- `GET /healthz`
- `GET /readyz`
- `GET /api/v1/inventory/products`
- `POST /api/v1/inventory/products`
- `GET /api/v1/inventory/products/{product_id}`

## Migraciones con Alembic

Alembic es el mecanismo oficial para cambios de esquema.

Rutas relevantes:

- migraciones: `services/inventory-service/alembic/versions/`
- primera revision: `services/inventory-service/alembic/versions/20260306_0001_create_products_table.py`

Aplicar migraciones:

```bash
mise run backend-migrate
```

Crear una revision manual:

```bash
cd services/inventory-service
uv run --extra dev alembic revision -m "describe-tu-cambio"
```

Previsualizar el SQL generado:

```bash
cd services/inventory-service
uv run --extra dev alembic upgrade head --sql
```

Regla recomendada:

- todo cambio en modelos persistentes debe ir acompañado de una migracion Alembic explicita.

## Observabilidad con Sentry

Variables opcionales del backend:

- `INVENTORY_SENTRY_DSN`
- `INVENTORY_SENTRY_TRACES_SAMPLE_RATE`

## Limites arquitectonicos esperados

- dominio y aplicacion separados de infraestructura,
- adaptadores y API construidos sobre puertos,
- cambios de persistencia acompañados de tests y migraciones,
- documentacion actualizada si cambia comportamiento o contrato.

Referencia adicional: `services/inventory-service/README.md`
