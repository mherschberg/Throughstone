#!/usr/bin/env bash
#
# doctor.sh — Throughstone helper dispatcher.
#
# Central command implementation for the root-level doctor.sh wrapper. Keeps common read-only
# project checks behind one entry point while delegating to the existing Bash helpers.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# usage — print the public command surface. Keep this list limited to implemented commands so
# the root shortcut stays discoverable without advertising future tooling.
usage() {
  cat <<'USAGE'
doctor.sh — Throughstone project helper dispatcher.

Usage: ./doctor.sh <command> [args]

Commands:
  status    Show where the project is, the next action, and check-in cadence.
  check     Run the read-only structural project checks.
  links     Check durable docs for stale local Markdown links.
  help      Show this help.

Examples:
  ./doctor.sh status
  ./doctor.sh check
  ./doctor.sh links
USAGE
}

# run_helper NAME [ARGS...] — exec the selected docs-hub helper with forwarded arguments.
# The dispatcher owns only command discovery and error reporting; status.sh/check.sh keep their
# own behavior, output, and exit codes.
run_helper() {
  local name="$1" script
  shift
  script="$SCRIPT_DIR/$name.sh"

  if [ ! -x "$script" ]; then
    echo "doctor.sh: helper is missing or not executable: $script" >&2
    return 1
  fi

  exec "$script" "$@"
}

# Command surface: keep this intentionally small until the underlying Bash helpers exist.
# Unknown commands are CLI usage errors; implemented commands delegate without interpretation.
cmd="${1:-help}"
case "$cmd" in
  -h|--help|help)
    usage
    ;;
  status)
    shift
    run_helper status "$@"
    ;;
  check)
    shift
    run_helper check "$@"
    ;;
  links)
    shift
    run_helper links "$@"
    ;;
  *)
    echo "doctor.sh: unknown command: $cmd" >&2
    echo "Try './doctor.sh --help'." >&2
    exit 2
    ;;
esac
