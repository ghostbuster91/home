#!/usr/bin/env bash
set -uo pipefail

action="${1:-all}"
case "$action" in
compile)
    steps=(compile)
    ;;
upload)
    steps=(upload)
    ;;
all)
    steps=(compile upload)
    ;;
*)
    echo "usage: $0 [compile|upload|all]" >&2
    exit 1
    ;;
esac

cd "$(dirname "$0")" || exit 1

failed=()
for f in dimmer-*.yaml; do
    for cmd in "${steps[@]}"; do
        echo "=== esphome $cmd $f ==="
        if ! esphome "$cmd" "$f"; then
            failed+=("$f ($cmd)")
            # don't try to upload a firmware that failed to build
            break
        fi
    done
done

if ((${#failed[@]})); then
    printf 'Failed:\n' >&2
    printf '  %s\n' "${failed[@]}" >&2
    exit 1
fi
