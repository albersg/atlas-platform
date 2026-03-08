import sentry_sdk
from fastapi import FastAPI, HTTPException, status
from inventory_service.inventory.adapters.api.http.router import build_inventory_router
from inventory_service.inventory.adapters.persistence.sqlalchemy.uow import (
    SqlAlchemyInventoryUnitOfWork,
)
from inventory_service.inventory.ports.uow import InventoryUnitOfWork
from inventory_service.shared.config import settings
from inventory_service.shared.db import create_session_factory
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sqlalchemy import text


def create_app() -> FastAPI:
    if settings.sentry_dsn:
        sentry_sdk.init(
            dsn=settings.sentry_dsn,
            environment=settings.app_env,
            traces_sample_rate=settings.sentry_traces_sample_rate,
            integrations=[FastApiIntegration()],
        )

    app = FastAPI(title=settings.app_name)

    session_factory = create_session_factory(settings.database_url)

    def uow_factory() -> InventoryUnitOfWork:
        return SqlAlchemyInventoryUnitOfWork(session_factory)

    @app.get("/healthz", tags=["health"])
    def healthcheck() -> dict[str, str]:
        return {"status": "ok", "service": settings.app_name}

    @app.get("/readyz", tags=["health"])
    def readinesscheck() -> dict[str, str]:
        try:
            with session_factory() as session:
                session.execute(text("SELECT 1"))
        except Exception as exc:  # pragma: no cover - exercised in runtime environments
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="database unavailable",
            ) from exc

        return {"status": "ok", "service": settings.app_name}

    app.include_router(build_inventory_router(uow_factory=uow_factory))
    return app


app = create_app()
