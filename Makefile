SHELL := /bin/sh
ENV_FILE ?= .env
DOCKER ?= $(shell command -v docker 2>/dev/null || echo "docker")

define DOCKER_COMPOSE
	if $(DOCKER) compose version >/dev/null 2>&1; then \
		echo "$(DOCKER) compose"; \
	elif command -v docker-compose >/dev/null 2>&1; then \
		echo "docker-compose"; \
	else \
		echo "ERROR: Docker Compose not found. Install docker compose command (v2 plugin preferred)." 1>&2; \
		exit 1; \
	fi
endef

.PHONY: help init pull up start down diagnose

help:
	@echo ""
	@echo "+----------------+-----------------------------------------------+"
	@echo "| Target         | Description                                   |"
	@echo "+----------------+-----------------------------------------------+"
	@echo "| help           | Show this help                                |"
	@echo "| init           | Create data dirs and .env if missing          |"
	@echo "| pull           | Pull Docker image                             |"
	@echo "| up             | Start services                                |"
	@echo "| start          | init + pull + up                              |"
	@echo "| down           | Stop services                                 |"
	@echo "+----------------+-----------------------------------------------+"
	@echo ""
	@echo "+----------------+-----------------------------------------------+"
	@echo "| Override       | Usage                                         |"
	@echo "+----------------+-----------------------------------------------+"
	@echo "| DOCKER         | make DOCKER=/path/to/docker up                |"
	@echo "| ENV_FILE       | make ENV_FILE=.env up                         |"
	@echo "+----------------+-----------------------------------------------+"

init:
	@mkdir -p ./data ./ssh_keys
	@chmod 770 ./data ./ssh_keys
	@if [ ! -f "$(ENV_FILE)" ]; then \
		if [ -f ".env.local" ]; then \
			cp .env.local "$(ENV_FILE)"; \
			echo "Created $(ENV_FILE) from .env.local (edit if needed)."; \
		else \
			echo "No .env.local found. Continuing without $(ENV_FILE)."; \
		fi \
	fi
	@grep -q '^DOCKER_SOCK=' "$(ENV_FILE)" 2>/dev/null || { \
		if [ -S "$${XDG_RUNTIME_DIR}/docker.sock" ]; then \
			echo "DOCKER_SOCK=$${XDG_RUNTIME_DIR}/docker.sock" >> "$(ENV_FILE)"; \
		elif [ -S "/run/user/$$(id -u)/docker.sock" ]; then \
			echo "DOCKER_SOCK=/run/user/$$(id -u)/docker.sock" >> "$(ENV_FILE)"; \
		elif [ -S /var/run/docker.sock ]; then \
			echo "DOCKER_SOCK=/var/run/docker.sock" >> "$(ENV_FILE)"; \
		else \
			echo "DOCKER_SOCK=/var/run/docker.sock" >> "$(ENV_FILE)"; \
		fi; \
	}

diagnose:
	@echo "=== Host environment ==="
	@echo "Host user: $$(id)"
	@echo "Host data dir: $$(ls -ldn ./data 2>/dev/null || echo 'NOT FOUND')"
	@echo "Host ssh_keys dir: $$(ls -ldn ./ssh_keys 2>/dev/null || echo 'NOT FOUND')"
	@echo "Docker socket: $$(ls -ln $${DOCKER_SOCK:-/var/run/docker.sock} 2>/dev/null || echo 'NOT FOUND')"
	@echo "Docker info: $$($(DOCKER) info --format 'rootless={{.SecurityOptions}}' 2>/dev/null || echo 'UNAVAILABLE')"
	@echo ""
	@echo "=== Container environment ==="
	@$(DOCKER) run --rm --entrypoint sh ghcr.io/intellisoftalpin/isa:$${ISA_IMAGE_TAG:-latest} -c '\
		echo "Container user: $$(id)"; \
		echo "Container /app/data owner: $$(ls -ldn /app/data 2>/dev/null || echo NOT FOUND)"; \
		echo "Container /app owner: $$(ls -ldn /app 2>/dev/null || echo NOT FOUND)"; \
		echo "Writable test /app/data: $$(touch /app/data/.writetest 2>&1 && rm -f /app/data/.writetest && echo YES || echo NO)"' 2>/dev/null || echo "Could not run container"
	@echo ""
	@echo "=== Container with user: 0:0 and volume mount ==="
	@$(DOCKER) run --rm --user 0:0 \
		-v "$$(pwd)/data:/app/data" \
		-v "$$(pwd)/ssh_keys:/app/ssh_keys" \
		--entrypoint sh ghcr.io/intellisoftalpin/isa:$${ISA_IMAGE_TAG:-latest} -c '\
		echo "Container user: $$(id)"; \
		echo "Mounted /app/data owner: $$(ls -ldn /app/data)"; \
		echo "Writable test: $$(touch /app/data/.writetest 2>&1 && rm -f /app/data/.writetest && echo YES || echo NO)"' 2>/dev/null || echo "Could not run container with volume mount"

pull:
	@COMPOSE="$$(sh -c '$(DOCKER_COMPOSE)')" && $$COMPOSE --env-file "$(ENV_FILE)" pull

up: init
	@COMPOSE="$$(sh -c '$(DOCKER_COMPOSE)')" && $$COMPOSE --env-file "$(ENV_FILE)" up -d

start: init pull up

down:
	@COMPOSE="$$(sh -c '$(DOCKER_COMPOSE)')" && $$COMPOSE --env-file "$(ENV_FILE)" down
