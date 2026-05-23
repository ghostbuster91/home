#!/usr/bin/env bash
set -uo pipefail

action="${1:-}"
case "$action" in
  build) cmd=compile; extra=() ;;
  flash) cmd=run;     extra=(--no-logs) ;;
  *) echo "usage: $0 {build|flash}" >&2; exit 1 ;;
esac

cd "$(dirname "$0")"

failed=()
for f in dimmer-*.yaml; do
  echo "=== esphome $cmd $f ==="
  if ! esphome "$cmd" "${extra[@]}" "$f"; then
    failed+=("$f")
  fi
done

if (( ${#failed[@]} )); then
  echo "Failed: ${failed[*]}" >&2
  exit 1
fi
