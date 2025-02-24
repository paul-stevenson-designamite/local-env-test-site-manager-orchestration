# Helper variables
DOCKER_COMPOSE = docker-compose
APPS = new-ui legacy api
DOCKER_BAKE = docker buildx bake

# Colors for pretty output
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help install up down restart status status-detailed logs composer-install npm-install migrate fresh seed clear-cache test build

help:
	@echo "Available commands:"
	@echo "${GREEN}make install${NC}         - Install dependencies for all apps"
	@echo "${GREEN}make up${NC}              - Start all containers using current branches"
	@echo "${GREEN}make up-branch BRANCH=branch_name${NC} - Start containers using specific branch in all repos"
	@echo "${GREEN}make down${NC}            - Stop all containers"
	@echo "${GREEN}make restart${NC}         - Restart all containers"
	@echo "${GREEN}make status${NC}          - Show container and repo status (brief)"
	@echo "${GREEN}make status-detailed${NC} - Show detailed repo status"
	@echo "${GREEN}make logs${NC}            - Show container logs"
	@echo "${GREEN}make build${NC}           - Build images using Docker Bake"
	@echo ""
	@echo "App-specific commands (replace APP with new-ui, legacy, or api):"
	@echo "${GREEN}make install-APP${NC}     - Install dependencies for specific app"
	@echo "${GREEN}make migrate-APP${NC}     - Run migrations for specific app"
	@echo "${GREEN}make fresh-APP${NC}       - Fresh migrations for specific app"
	@echo "${GREEN}make seed-APP${NC}        - Seed database for specific app"
	@echo "${GREEN}make test-APP${NC}        - Run tests for specific app"
	@echo "${GREEN}make clear-cache-APP${NC} - Clear cache for specific app"
	@echo "${GREEN}make build-APP${NC}       - Build specific app with Docker Bake"

# General commands
up:
	${DOCKER_COMPOSE} up -d

up-branch:
	@if [ -z "$(BRANCH)" ]; then \
		echo "${RED}Error: Please specify a branch with BRANCH=branch_name${NC}"; \
		exit 1; \
	fi
	@echo "${GREEN}Starting containers with branch: $(BRANCH)${NC}"
	BRANCH=$(BRANCH) ${DOCKER_BAKE} && ${DOCKER_COMPOSE} up -d

down:
	${DOCKER_COMPOSE} down

restart:
	${DOCKER_COMPOSE} restart

# Status commands
status:
	@echo "\n${BLUE}Container Status:${NC}"
	@${DOCKER_COMPOSE} ps
	@echo "\n${BLUE}Repository Status:${NC}"
	@for app in ${APPS}; do \
		echo "\n${GREEN}$$app Repository:${NC}"; \
		cd site-manager-$$app && \
		git branch --show-current | tr -d '\n' && printf " " && \
		git rev-parse --short HEAD | tr -d '\n' && printf " " && \
		BRANCH=$$(git branch --show-current) && \
		BEHIND=$$(git rev-list --count HEAD..origin/$$BRANCH 2>/dev/null || echo "N/A") && \
		if [ "$$BEHIND" = "0" ] || [ "$$BEHIND" = "N/A" ]; then \
			echo "HEAD"; \
		else \
			echo "HEAD-$$BEHIND"; \
		fi && \
		cd ..; \
	done

status-detailed:
	@for app in ${APPS}; do \
		echo "\n${GREEN}$$app Repository Status:${NC}"; \
		echo "Branch: $$(cd site-manager-$$app && git branch --show-current)"; \
		echo "Commit: $$(cd site-manager-$$app && git rev-parse --short HEAD)"; \
		echo "Commit Message: $$(cd site-manager-$$app && git log -1 --pretty=%B | head -1)"; \
		echo "Last Modified: $$(cd site-manager-$$app && git log -1 --pretty=format:'%ar')"; \
		BRANCH=$$(cd site-manager-$$app && git branch --show-current); \
		BEHIND=$$(cd site-manager-$$app && git rev-list --count HEAD..origin/$$BRANCH 2>/dev/null || echo "N/A"); \
		if [ "$$BEHIND" = "0" ]; then \
			echo "Branch Status: ${GREEN}Up to date with origin${NC}"; \
		elif [ "$$BEHIND" = "N/A" ]; then \
			echo "Branch Status: ${YELLOW}Remote branch not found${NC}"; \
		else \
			echo "Branch Status: ${RED}$$BEHIND commits behind origin${NC}"; \
		fi; \
		cd site-manager-$$app && git status --porcelain | grep -v '??' | sed 's/^/  /' && cd ..; \
	done


logs:
	${DOCKER_COMPOSE} logs -f

# Build commands using Docker Bake
build:
	${DOCKER_BAKE}

build-%:
	${DOCKER_BAKE} $*

# Install all dependencies
install: install-new-ui install-legacy install-api

# App-specific installation
install-new-ui: composer-install-new-ui npm-install-new-ui
install-legacy: composer-install-legacy npm-install-legacy
install-api: composer-install-api

# Composer commands
composer-install-%:
	${DOCKER_COMPOSE} run --rm $*-composer install

# NPM commands
npm-install-new-ui:
	${DOCKER_COMPOSE} run --rm new-ui-npm install

npm-install-legacy:
	${DOCKER_COMPOSE} run --rm legacy-npm install

# Artisan commands
migrate-%:
	${DOCKER_COMPOSE} run --rm $*-artisan migrate

fresh-%:
	${DOCKER_COMPOSE} run --rm $*-artisan migrate:fresh

seed-%:
	${DOCKER_COMPOSE} run --rm $*-artisan db:seed

clear-cache-%:
	${DOCKER_COMPOSE} run --rm $*-artisan cache:clear
	${DOCKER_COMPOSE} run --rm $*-artisan config:clear
	${DOCKER_COMPOSE} run --rm $*-artisan route:clear
	${DOCKER_COMPOSE} run --rm $*-artisan view:clear

# Testing
test-%:
	${DOCKER_COMPOSE} run --rm $*-artisan test

# Development helpers
dev-new-ui:
	${DOCKER_COMPOSE} run --rm new-ui-npm run dev

dev-legacy:
	${DOCKER_COMPOSE} run --rm legacy-npm run dev

# Watch commands
watch-new-ui:
	${DOCKER_COMPOSE} run --rm new-ui-npm run watch

watch-legacy:
	${DOCKER_COMPOSE} run --rm legacy-npm run watch

# Build commands for UI
build-new-ui:
	${DOCKER_COMPOSE} run --rm new-ui-npm run build

build-legacy:
	${DOCKER_COMPOSE} run --rm legacy-npm run build