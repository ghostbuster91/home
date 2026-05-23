#!/usr/bin/env bash
set -uo pipefail

action="${1:-}"
case "$action" in
compile)
    cmd=compile
    extra=()
    ;;
upload)
    cmd=upload
    extra=()
    ;;
*)
    echo "usage: $0 {compile|upload}" >&2
    exit 1
    ;;
esac

cd "$(dirname "$0")"

failed=()
for f in dimmer-*.yaml; do
    echo "=== esphome $cmd $f ==="
    if ! esphome "$cmd" "${extra[@]}" "$f"; then
        failed+=("$f")
    fi
done

if ((${#failed[@]})); then
    echo "Failed: ${failed[*]}" >&2
    exit 1
fi
