#!/usr/bin/env bash
set -euo pipefail

echo "[cleriq-entrypoint] Pornesc Caddy in background..."
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
CADDY_PID=$!

# Forward SIGTERM/SIGINT spre Caddy ca sa se inchida curat (RunPod stop = gratios).
trap 'echo "[cleriq-entrypoint] Opresc Caddy (PID=$CADDY_PID)..."; kill -TERM $CADDY_PID 2>/dev/null || true' SIGTERM SIGINT

# Mic delay defensiv (Caddy bind pe socket).
sleep 1

if ! kill -0 $CADDY_PID 2>/dev/null; then
    echo "[cleriq-entrypoint] EROARE: Caddy nu a pornit." >&2
    exit 1
fi

echo "[cleriq-entrypoint] Caddy OK (PID=$CADDY_PID). Cedez control la entrypoint-ul original WhisperX."

# Exec la entrypoint-ul original al imaginii base (wrapper-ul WhisperX pe :9000).
# `exec` inlocuieste procesul curent — wrapper-ul devine procesul principal
# si primeste direct toate semnalele din container.
exec /workspace/entrypoint.sh "$@"
