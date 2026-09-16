# Minimal Dockerfile for the "Docker Layer Caching & GHCR" lab.
# Layer ordering matters here on purpose: things that rarely change go
# first (so they get CACHED), things that change often go last.

FROM ubuntu:22.04

# Rarely changes -> should show as CACHED on repeat runs
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Changes most often -> rebuilt whenever README.md changes
COPY README.md .

CMD ["cat", "/app/README.md"]
