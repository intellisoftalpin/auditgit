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

.PHONY: help init pull up start down

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
	@grep -q '^DOCKER_GID=' "$(ENV_FILE)" 2>/dev/null || echo "DOCKER_GID=$$(id -g)" >> "$(ENV_FILE)"
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

pull:
	@COMPOSE="$$(sh -c '$(DOCKER_COMPOSE)')" && $$COMPOSE --env-file "$(ENV_FILE)" pull

up: init
	@COMPOSE="$$(sh -c '$(DOCKER_COMPOSE)')" && $$COMPOSE --env-file "$(ENV_FILE)" up -d

start: init pull up

down:
	@COMPOSE="$$(sh -c '$(DOCKER_COMPOSE)')" && $$COMPOSE --env-file "$(ENV_FILE)" down
