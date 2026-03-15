#!/usr/bin/env bash
set -euo pipefail

QUIET=0

if [[ "${1:-}" = "--quiet" ]]; then
  QUIET=1
  shift
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker es obligatorio para usar Docker Compose en este repositorio." >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose no esta disponible. Instala el plugin oficial de Docker Compose antes de continuar." >&2
  exit 1
fi

if [[ "$QUIET" = "1" ]]; then
  exit 0
fi

exec docker compose "$@"
