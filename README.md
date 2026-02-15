# ISA Scanner (Docker)

[![Container image (latest)](https://img.shields.io/badge/ghcr.io-intellisoftalpin%2Fisa%3Alatest-blue?logo=docker)](https://github.com/orgs/intellisoftalpin/packages/container/package/isa)

Run **ISA Scanner** locally using Docker Compose. The published image is **multi-arch** (works on **linux/amd64** and **linux/arm64**), so it runs on Intel/AMD machines and Apple Silicon.

> Pull the latest image:
> `docker pull ghcr.io/intellisoftalpin/isa:latest`

## Requirements

- Linux/macOS/Windows
- Docker Engine / Docker Desktop
- Docker Compose (both `docker compose` and `docker-compose` are supported)

## Quick start

### Docker Compose Sample

```yaml
version: "3.8"
services:
  isa-scanner:
    image: ghcr.io/intellisoftalpin/isa:${ISA_IMAGE_TAG:-latest}
    container_name: isa-scanner
    ports:
      - "${ISA_PORT:-18080}:18080"
    volumes:
      - "${ISA_DATA_HOST_DIR:-./data}:/app/data"
      - "${ISA_SSH_KEYS_HOST_DIR:-./ssh_keys}:/app/ssh_keys"
    restart: unless-stopped
    environment:
      - ISA_PORT=18080
      - ISA_DATA_DIR=/app/data
      - LOG_LEVEL=${LOG_LEVEL:-info}
    healthcheck:
      test: ["CMD", "curl", "-fsS", "http://localhost:18080/health"]
      interval: 30s
      timeout: 10s
      start_period: 30s
      retries: 3
    labels:
      - "com.centurylinklabs.watchtower.enable=true"

  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower
    restart: unless-stopped
    environment:
      - TZ=Europe/Stockholm
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command:
      - --label-enable
      - --cleanup
      - --schedule
      - "0 7 * * *"
      - --rolling-restart
```

### Bash

```bash
chmod +x install.sh update.sh
./install.sh
./update.sh
```

### Makefile

```bash
make help
make start
```

### Windows (PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
powershell -ExecutionPolicy Bypass -File .\update.ps1
```

### Windows (WSL)

```bash
wsl bash ./install.sh
wsl bash ./update.sh
```

> Use `install_wsl_dependencies.sh` to install `dos2unix`
> and convert scripts/env files to Unix line endings if needed.

## Stop / remove containers

```bash
docker compose down
# or: docker-compose down
# or: make down
```

## Health endpoint

- http://localhost:${ISA_PORT}/health

