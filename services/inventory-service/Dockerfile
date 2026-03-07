FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app/src

WORKDIR /app

COPY pyproject.toml /app/pyproject.toml
COPY src /app/src
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir .

COPY alembic.ini /app/alembic.ini
COPY alembic /app/alembic
COPY scripts/start.sh /app/scripts/start.sh
RUN chmod +x /app/scripts/start.sh && \
    useradd --create-home --uid 10001 appuser && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 8000
CMD ["/app/scripts/start.sh"]
