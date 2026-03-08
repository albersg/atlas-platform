#!/usr/bin/env sh
set -eu

cd /app
if [ "${RUN_MIGRATIONS_ON_STARTUP:-1}" = "1" ]; then
  /app/scripts/migrate.sh
fi
exec uvicorn inventory_service.main:app --host 0.0.0.0 --port 8000
