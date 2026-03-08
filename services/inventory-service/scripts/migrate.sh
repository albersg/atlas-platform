#!/usr/bin/env sh
set -eu

cd /app

python - <<'PY'
from __future__ import annotations

import os
import sys
import time

from alembic import command
from alembic.config import Config
import psycopg
from sqlalchemy.engine import make_url


dsn = os.environ["INVENTORY_DATABASE_URL"]
psycopg_dsn = make_url(dsn).set(drivername="postgresql").render_as_string(hide_password=False)
attempts = int(os.environ.get("DB_WAIT_MAX_ATTEMPTS", "60"))
sleep_seconds = float(os.environ.get("DB_WAIT_SLEEP_SECONDS", "2"))
lock_id = int(os.environ.get("DB_MIGRATION_LOCK_ID", "18436751"))


def wait_for_database() -> None:
    for attempt in range(1, attempts + 1):
        try:
            with psycopg.connect(psycopg_dsn, connect_timeout=5) as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT 1")
            print(f"database reachable after {attempt} attempt(s)", file=sys.stderr)
            return
        except Exception as exc:  # pragma: no cover - exercised in containers
            if attempt == attempts:
                raise RuntimeError(
                    f"database did not become ready after {attempts} attempts"
                ) from exc
            print(
                f"waiting for database (attempt {attempt}/{attempts}): {exc}",
                file=sys.stderr,
            )
            time.sleep(sleep_seconds)


wait_for_database()

with psycopg.connect(psycopg_dsn, autocommit=True) as conn:
    with conn.cursor() as cur:
        print(f"acquiring migration advisory lock {lock_id}", file=sys.stderr)
        cur.execute("SELECT pg_advisory_lock(%s)", (lock_id,))

    try:
        config = Config("alembic.ini")
        config.set_main_option("sqlalchemy.url", dsn)
        command.upgrade(config, "head")
    finally:
        with conn.cursor() as cur:
            cur.execute("SELECT pg_advisory_unlock(%s)", (lock_id,))
        print(f"released migration advisory lock {lock_id}", file=sys.stderr)
PY
