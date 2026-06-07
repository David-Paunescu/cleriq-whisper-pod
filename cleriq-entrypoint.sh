#!/usr/bin/env bash
set -uo pipefail

echo "[cleriq-entrypoint] Pornesc Caddy in background..."
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
CADDY_PID=$!

trap 'echo "[cleriq-entrypoint] Opresc Caddy (PID=$CADDY_PID)..."; kill -TERM $CADDY_PID 2>/dev/null || true' SIGTERM SIGINT

sleep 1

if ! kill -0 $CADDY_PID 2>/dev/null; then
    echo "[cleriq-entrypoint] EROARE: Caddy nu a pornit." >&2
    exit 1
fi

echo "[cleriq-entrypoint] Caddy OK (PID=$CADDY_PID). Pornesc wrapper-ul WhisperX..."

# Imaginea base publicata ca :latest este o versiune mai veche (pre-v0.3.0) care
# nu are entrypoint.sh — apelam direct uvicorn pe modulul Python al wrapper-ului,
# localizat la /workspace/app/main.py (confirmat din traceback-uri upstream).
if [ -f "/workspace/app/main.py" ]; then
    echo "[cleriq-entrypoint] Working dir: /workspace, module: app.main:app, host: 0.0.0.0, port: 9000"
    cd /workspace
    exec python3 -m uvicorn app.main:app --host 0.0.0.0 --port 9000 --log-level info
fi

# Fallback diagnostic daca structura e diferita.
echo "[cleriq-entrypoint] EROARE: /workspace/app/main.py nu exista." >&2
echo "[cleriq-entrypoint] Listing /workspace/ pentru diagnostic:" >&2
ls -la /workspace/ 2>&1 >&2 || true
echo "[cleriq-entrypoint] Listing /workspace/app/ (daca exista):" >&2
ls -la /workspace/app/ 2>&1 >&2 || echo "(/workspace/app/ nu exista)" >&2
echo "[cleriq-entrypoint] Pastrez container alive pentru debugging." >&2
sleep infinity
