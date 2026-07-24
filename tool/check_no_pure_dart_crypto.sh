#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PATTERN='package:(crypto|pointycastle)/|Random\.secure\('

if rg -n "$PATTERN" lib test tool --glob '!tool/check_no_pure_dart_crypto.sh'; then
  echo "Found disallowed pure-Dart crypto imports or Random.secure() usage." >&2
  exit 1
fi

echo "No disallowed pure-Dart crypto imports found."
