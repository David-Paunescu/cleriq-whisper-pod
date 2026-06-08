# syntax=docker/dockerfile:1.7

# Stage 1: build Caddy custom cu plugin mholt/caddy-ratelimit.
# Imaginea oficială caddy:*-builder are Go + xcaddy pre-installed.
# La upgrade Caddy: schimbă versiunea în AMBELE locuri (FROM + xcaddy build).
FROM caddy:2.8.4-builder AS caddy-builder
RUN xcaddy build v2.8.4 \
    --with github.com/mholt/caddy-ratelimit

# Stage 2: runtime.
# Imagine base pinned la digest pentru reproducibilitate strictă.
# Sursă: learnedmachine/whisperx-asr-service:latest (PyTorch 2.7.1 / cu126, RTX 4090 OK).
# Pentru upgrade upstream, actualizează digest-ul după ce verifici pe hub.docker.com.
FROM learnedmachine/whisperx-asr-service@sha256:84f845baf0c7291de843dcc921e64105d1899e82a6e54730319de55814244f50

# Copy binary Caddy custom-built (cu plugin rate_limit baked-in).
COPY --from=caddy-builder /usr/bin/caddy /usr/local/bin/caddy
RUN chmod +x /usr/local/bin/caddy

# Caddyfile + entrypoint custom (nume distinct ca să nu se ciocnească
# cu /workspace/entrypoint.sh-ul moștenit din imaginea base).
COPY Caddyfile /etc/caddy/Caddyfile
COPY cleriq-entrypoint.sh /usr/local/bin/cleriq-entrypoint.sh
RUN chmod +x /usr/local/bin/cleriq-entrypoint.sh

# Caddy ascultă pe 8080 (port public RunPod); wrapper rămâne intern pe 9000.
EXPOSE 8080

# Suprascriem CMD-ul original (/workspace/entrypoint.sh) cu wrapper-ul nostru,
# care pornește Caddy și apoi face exec la entrypoint-ul original.
CMD ["/usr/local/bin/cleriq-entrypoint.sh"]
