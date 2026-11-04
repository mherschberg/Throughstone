#!/usr/bin/env bash
#
# doctor.sh — root Throughstone doctor wrapper.
#
# Delegates to the docs hub's dispatcher, so command behavior has exactly one implementation.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$ROOT/Code/{{PROJECT}}-docs/scripts/doctor.sh"

if [ ! -x "$SCRIPT" ]; then
  echo "doctor.sh: dispatcher is missing or not executable: $SCRIPT" >&2
  exit 1
fi

exec "$SCRIPT" "$@"
