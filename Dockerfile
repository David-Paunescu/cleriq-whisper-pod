# syntax=docker/dockerfile:1.7

# Imagine base pinned la digest pentru reproducibilitate strictă.
# Sursă: learnedmachine/whisperx-asr-service:latest (PyTorch 2.7.1 / cu126, RTX 4090 OK).
# Pentru upgrade upstream, actualizează digest-ul după ce verifici pe hub.docker.com.
FROM learnedmachine/whisperx-asr-service@sha256:84f845baf0c7291de843dcc921e64105d1899e82a6e54730319de55814244f50

# Install Caddy v2 ca reverse proxy în fața wrapper-ului WhisperX.
# Pas 2: proxy simplu, fără auth. Auth-ul (Bearer + IP allowlist + rate limit) = Pas 3+.
ARG CADDY_VERSION=2.8.4
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_amd64.tar.gz" \
        | tar -xz -C /usr/local/bin caddy \
    && chmod +x /usr/local/bin/caddy \
    && rm -rf /var/lib/apt/lists/*

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
