#!/bin/sh
set -e

# Guard critic: refuzăm să pornim pod-ul fără cheie primară.
# Fără asta, matcher-ul @key_primary din Caddyfile s-ar expanda la `Bearer ` (gol),
# care e prins de @empty_bearer — dar e mai curat să eșuăm aici, vizibil în log-uri.
if [ -z "$WHISPER_API_KEY" ]; then
    echo "FATAL: WHISPER_API_KEY env var nu este setat. Refuz să pornesc pod-ul fără auth."
    exit 1
fi

echo "[entrypoint] Validez Caddyfile..."
caddy validate --config /etc/caddy/Caddyfile

echo "[entrypoint] Pornesc Caddy pe portul 8080 (Bearer auth activ)..."
caddy run --config /etc/caddy/Caddyfile &

echo "[entrypoint] Pornesc wrapper Whisper pe portul 9000..."
cd /workspace && exec python3 -m uvicorn app.main:app --host 0.0.0.0 --port 9000
