from pathlib import Path

from fastapi.testclient import TestClient
from inventory_service.inventory.adapters.persistence.sqlalchemy.models import ProductModel
from inventory_service.main import create_app
from inventory_service.shared.config import Settings
from inventory_service.shared.db import Base, create_session_factory


def test_settings_defaults_and_overrides() -> None:
    defaults = Settings()
    assert defaults.app_name == "inventory-service"
    assert defaults.app_env == "dev"
    assert defaults.sentry_dsn is None
    assert defaults.sentry_traces_sample_rate == 0.0

    overridden = Settings(
        app_name="inventory-service-test",
        app_env="test",
        database_url="sqlite+pysqlite:///tmp/test.db",
        sentry_dsn="https://example@o0.ingest.sentry.io/0",
        sentry_traces_sample_rate=0.5,
    )
    assert overridden.app_name == "inventory-service-test"
    assert overridden.app_env == "test"
    assert overridden.database_url.startswith("sqlite+pysqlite://")
    assert overridden.sentry_dsn is not None
    assert overridden.sentry_traces_sample_rate == 0.5


def test_create_app_healthcheck_and_no_sentry_when_dsn_missing(monkeypatch) -> None:
    from inventory_service import main as main_module

    init_calls: list[dict] = []

    def fake_sentry_init(**kwargs):
        init_calls.append(kwargs)

    monkeypatch.setattr(main_module.sentry_sdk, "init", fake_sentry_init)
    monkeypatch.setattr(main_module.settings, "sentry_dsn", None)
    monkeypatch.setattr(main_module.settings, "app_name", "inventory-service")

    app = create_app()
    client = TestClient(app)
    response = client.get("/healthz")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "service": "inventory-service"}
    assert init_calls == []


def test_create_app_initializes_sentry_when_dsn_present(monkeypatch) -> None:
    from inventory_service import main as main_module

    init_calls: list[dict] = []

    def fake_sentry_init(**kwargs):
        init_calls.append(kwargs)

    monkeypatch.setattr(main_module.sentry_sdk, "init", fake_sentry_init)
    monkeypatch.setattr(main_module.settings, "sentry_dsn", "https://example@o0.ingest.sentry.io/0")
    monkeypatch.setattr(main_module.settings, "app_env", "test")
    monkeypatch.setattr(main_module.settings, "sentry_traces_sample_rate", 0.25)

    create_app()

    assert len(init_calls) == 1
    assert init_calls[0]["environment"] == "test"
    assert init_calls[0]["traces_sample_rate"] == 0.25


def test_create_app_wires_inventory_router_with_real_uow(monkeypatch, tmp_path: Path) -> None:
    from inventory_service import main as main_module

    database_url = f"sqlite+pysqlite:///{tmp_path / 'inventory-main.db'}"
    session_factory = create_session_factory(database_url)
    with session_factory() as session:
        Base.metadata.create_all(bind=session.get_bind())

    monkeypatch.setattr(main_module.settings, "database_url", database_url)
    monkeypatch.setattr(main_module.settings, "sentry_dsn", None)
    monkeypatch.setattr(main_module.settings, "app_name", "inventory-service")

    app = create_app()
    client = TestClient(app)

    response = client.get("/api/v1/inventory/products")
    assert response.status_code == 200
    assert response.json() == []

    with session_factory() as session:
        assert session.query(ProductModel).count() == 0
