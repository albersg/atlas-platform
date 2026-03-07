from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "inventory-service"
    app_env: str = "dev"
    database_url: str = "postgresql+psycopg://postgres@localhost:5432/inventory"
    sentry_dsn: str | None = None
    sentry_traces_sample_rate: float = 0.0

    model_config = SettingsConfigDict(
        env_file=".env",
        env_prefix="INVENTORY_",
        extra="ignore",
    )


settings = Settings()
