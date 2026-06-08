#!/bin/sh
set -e

# Guard critic Pas 3: refuzăm să pornim pod-ul fără cheie primară de auth.
if [ -z "$WHISPER_API_KEY" ]; then
    echo "FATAL: WHISPER_API_KEY env var nu este setat. Refuz să pornesc pod-ul fără auth."
    exit 1
fi

# Pas 4 IP allowlist: default = allow all (dev convenient).
# Producție: setează CLERIQ_ALLOWED_IPS în RunPod template la IP-ul fix al serverului Cleriq.
if [ -z "$CLERIQ_ALLOWED_IPS" ]; then
    export CLERIQ_ALLOWED_IPS="0.0.0.0/0 ::/0"
    echo "[entrypoint] CLERIQ_ALLOWED_IPS nesetat — folosesc default 'allow all' (0.0.0.0/0 ::/0)."
else
    echo "[entrypoint] CLERIQ_ALLOWED_IPS = $CLERIQ_ALLOWED_IPS"
fi

echo "[entrypoint] Validez Caddyfile..."
caddy validate --config /etc/caddy/Caddyfile

echo "[entrypoint] Pornesc Caddy pe portul 8080 (Bearer auth + IP allowlist active)..."
caddy run --config /etc/caddy/Caddyfile &

echo "[entrypoint] Pornesc wrapper Whisper pe portul 9000..."
cd /workspace && exec python3 -m uvicorn app.main:app --host 0.0.0.0 --port 9000
