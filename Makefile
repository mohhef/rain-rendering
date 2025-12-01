# Makefile for Rain Rendering Docker Container
# Provides convenient commands for building and running the container

.PHONY: help build build-no-cache run shell verify clean test

# Image name
IMAGE_NAME = rain-rendering
IMAGE_TAG = latest

# Colors for output
BLUE = \033[0;34m
GREEN = \033[0;32m
RED = \033[0;31m
NC = \033[0m # No Color

help:
	@echo "$(BLUE)Rain Rendering - Docker Commands$(NC)"
	@echo ""
	@echo "Available commands:"
	@echo "  $(GREEN)make build$(NC)          - Build the Docker image"
	@echo "  $(GREEN)make build-no-cache$(NC) - Build the Docker image without cache"
	@echo "  $(GREEN)make run$(NC)            - Run the main_threaded.py script"
	@echo "  $(GREEN)make shell$(NC)          - Start an interactive shell in the container"
	@echo "  $(GREEN)make verify$(NC)         - Verify all dependencies are correctly installed"
	@echo "  $(GREEN)make test-simulator$(NC) - Test the weather particle simulator binary"
	@echo "  $(GREEN)make clean$(NC)          - Remove the Docker image"
	@echo "  $(GREEN)make clean-all$(NC)      - Remove all Docker images and containers"
	@echo ""
	@echo "Docker Compose commands:"
	@echo "  $(GREEN)make compose-build$(NC)  - Build using docker-compose"
	@echo "  $(GREEN)make compose-up$(NC)     - Start services using docker-compose"
	@echo "  $(GREEN)make compose-down$(NC)   - Stop services using docker-compose"
	@echo ""

build:
	@echo "$(BLUE)Building Docker image...$(NC)"
	@echo "This may take 20-30 minutes on first build."
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "$(GREEN)Build complete!$(NC)"

build-no-cache:
	@echo "$(BLUE)Building Docker image without cache...$(NC)"
	docker build --no-cache -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "$(GREEN)Build complete!$(NC)"

run:
	@echo "$(BLUE)Running main_threaded.py...$(NC)"
	docker run -it --rm \
		-v $(PWD):/workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		python3 main_threaded.py

shell:
	@echo "$(BLUE)Starting interactive shell...$(NC)"
	docker run -it --rm \
		-v $(PWD):/workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		/bin/bash

verify:
	@echo "$(BLUE)Running verification script...$(NC)"
	docker run -it --rm \
		-v $(PWD):/workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		/workspace/scripts/verify_docker.sh

test-simulator:
	@echo "$(BLUE)Testing weather particle simulator...$(NC)"
	@echo "The simulator will start. Type '0' and press Enter to exit."
	docker run -it --rm \
		-v $(PWD):/workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		/workspace/3rdparty/weather-particle-simulator/lin_x64/AHLSimulation

clean:
	@echo "$(RED)Removing Docker image...$(NC)"
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG)
	@echo "$(GREEN)Image removed!$(NC)"

clean-all:
	@echo "$(RED)Removing all Docker images and containers...$(NC)"
	docker system prune -a
	@echo "$(GREEN)Cleanup complete!$(NC)"

# Docker Compose commands
compose-build:
	@echo "$(BLUE)Building with docker-compose...$(NC)"
	docker-compose build
	@echo "$(GREEN)Build complete!$(NC)"

compose-up:
	@echo "$(BLUE)Starting services with docker-compose...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)Services started!$(NC)"

compose-down:
	@echo "$(BLUE)Stopping services...$(NC)"
	docker-compose down
	@echo "$(GREEN)Services stopped!$(NC)"

# X11 forwarding helpers (Linux only)
x11-enable:
	@echo "$(BLUE)Enabling X11 forwarding...$(NC)"
	xhost +local:docker
	@echo "$(GREEN)X11 forwarding enabled!$(NC)"

x11-disable:
	@echo "$(BLUE)Disabling X11 forwarding...$(NC)"
	xhost -local:docker
	@echo "$(GREEN)X11 forwarding disabled!$(NC)"

shell-x11:
	@echo "$(BLUE)Starting shell with X11 forwarding...$(NC)"
	docker run -it --rm \
		-e DISPLAY=$(DISPLAY) \
		-v /tmp/.X11-unix:/tmp/.X11-unix:rw \
		-v $(PWD):/workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		/bin/bash

# Development commands
dev-shell:
	@echo "$(BLUE)Starting development shell with mounted workspace...$(NC)"
	docker run -it --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		/bin/bash

# Check if Docker is installed
check-docker:
	@which docker > /dev/null || (echo "$(RED)Docker is not installed!$(NC)" && exit 1)
	@echo "$(GREEN)Docker is installed$(NC)"
	@docker --version

# Check if Docker Compose is installed
check-compose:
	@which docker-compose > /dev/null || (echo "$(RED)Docker Compose is not installed!$(NC)" && exit 1)
	@echo "$(GREEN)Docker Compose is installed$(NC)"
	@docker-compose --version

# Show Docker image info
info:
	@echo "$(BLUE)Docker Image Information$(NC)"
	@echo "Name: $(IMAGE_NAME):$(IMAGE_TAG)"
	@docker images $(IMAGE_NAME):$(IMAGE_TAG) || echo "$(RED)Image not built yet. Run 'make build' first.$(NC)"

# Show running containers
ps:
	@echo "$(BLUE)Running Containers$(NC)"
	@docker ps -a | grep $(IMAGE_NAME) || echo "No containers running"

# Install dependencies (build the image)
install: build verify
	@echo "$(GREEN)Installation complete!$(NC)"

# Default target
.DEFAULT_GOAL := help
