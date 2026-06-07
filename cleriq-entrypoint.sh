#!/usr/bin/env bash
# NOTA: NU folosim set -e ca sa putem afisa diagnostic complet la eroare
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

echo "[cleriq-entrypoint] Caddy OK (PID=$CADDY_PID). Caut entrypoint-ul original WhisperX..."

# Locatii probabile pentru entrypoint-ul original (variaza intre versiuni de imagine).
CANDIDATE_PATHS=(
    "/workspace/entrypoint.sh"
    "/entrypoint.sh"
    "/app/entrypoint.sh"
    "/opt/whisperx/entrypoint.sh"
    "/workspace/app/entrypoint.sh"
    "/usr/src/app/entrypoint.sh"
)

ORIGINAL_ENTRYPOINT=""
for path in "${CANDIDATE_PATHS[@]}"; do
    if [ -x "$path" ]; then
        ORIGINAL_ENTRYPOINT="$path"
        echo "[cleriq-entrypoint] Gasit: $path"
        break
    fi
done

if [ -n "$ORIGINAL_ENTRYPOINT" ]; then
    echo "[cleriq-entrypoint] Primele 3 linii ale fisierului (pentru diagnostic shebang/encoding):"
    head -3 "$ORIGINAL_ENTRYPOINT"
    echo "[cleriq-entrypoint] Cedez control la $ORIGINAL_ENTRYPOINT"
    exec "$ORIGINAL_ENTRYPOINT" "$@"
fi

# Nimic gasit - diagnostic complet pentru sesiunea urmatoare.
echo "" >&2
echo "[cleriq-entrypoint] === EROARE: entrypoint script negasit ===" >&2
echo "[cleriq-entrypoint] Locatii verificate (toate inexistente):" >&2
for path in "${CANDIDATE_PATHS[@]}"; do
    echo "  - $path" >&2
done

echo "" >&2
echo "[cleriq-entrypoint] === Diagnostic structura imagine ===" >&2

echo "" >&2
echo "[cleriq-entrypoint] Continut /:" >&2
ls -la / 2>&1 >&2

echo "" >&2
echo "[cleriq-entrypoint] Continut /workspace/ (daca exista):" >&2
ls -la /workspace/ 2>&1 >&2 || echo "(/workspace/ nu exista)" >&2

echo "" >&2
echo "[cleriq-entrypoint] Continut /app/ (daca exista):" >&2
ls -la /app/ 2>&1 >&2 || echo "(/app/ nu exista)" >&2

echo "" >&2
echo "[cleriq-entrypoint] Cautare 'entrypoint*' in primele 5 niveluri:" >&2
find / -maxdepth 5 -name "entrypoint*" -type f 2>/dev/null | head -20 >&2

echo "" >&2
echo "[cleriq-entrypoint] Verificare procese deja pornite:" >&2
ps auxf 2>&1 >&2 || ps -ef 2>&1 >&2

echo "" >&2
echo "[cleriq-entrypoint] Pastrez container alive (sleep infinity) pentru investigare via Web Terminal." >&2
echo "[cleriq-entrypoint] Termina pod-ul manual cand termini debugging-ul." >&2
sleep infinity
