FROM ghcr.io/astral-sh/uv:0.10.8 AS uv

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app/src
ENV UV_NO_DEV=1
ENV PATH=/app/.venv/bin:$PATH

WORKDIR /app

COPY --from=uv /uv /uvx /bin/

COPY pyproject.toml uv.lock /app/
RUN uv sync --locked --no-install-project --no-editable

COPY src /app/src
COPY alembic.ini /app/alembic.ini
COPY alembic /app/alembic
COPY scripts/start.sh /app/scripts/start.sh
COPY scripts/migrate.sh /app/scripts/migrate.sh
RUN uv sync --locked --no-editable && \
    chmod +x /app/scripts/start.sh /app/scripts/migrate.sh && \
    useradd --create-home --uid 10001 appuser && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 8000
CMD ["/app/scripts/start.sh"]
