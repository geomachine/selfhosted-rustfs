# include .env

# # Default directories if not set in env
# DATA_DIR ?= ./data
# CONFIG_DIR ?= ./config

# .PHONY: help build up start stop restart logs status clean backup restore binary rebuild

# help:
# 	@echo "RustFS Docker Makefile"
# 	@echo "---------------------"
# 	@echo "make build       - build rustfs docker image (uses rustfs-binary)"
# 	@echo "make up          - start rustfs container"
# 	@echo "make start       - alias for 'make up'"
# 	@echo "make stop        - stop rustfs container"
# 	@echo "make restart     - restart container"
# 	@echo "make logs        - follow logs"
# 	@echo "make status      - show running container status"
# 	@echo "make clean       - remove container and volumes (dangerous)"
# 	@echo "make backup      - backup rustfs data"
# 	@echo "make restore     - restore rustfs data from backup"
# 	@echo "make binary      - build RustFS binary from source"
# 	@echo "make rebuild     - rebuild binary + Docker image"
# 	@echo ""

# # Build RustFS Docker image
# build:
# 	@if [ -f ./rustfs-binary ]; then \
# 		echo "[+] Using existing rustfs-binary"; \
# 	else \
# 		echo "[!] rustfs-binary not found. Please build it first with 'make binary' or download it."; \
# 		exit 1; \
# 	fi
# 	docker build -t ${RUSTFS_IMAGE} .

# # Run Docker container
# up:
# 	@echo "[+] Ensuring data and config directories exist..."
# 	@mkdir -p $(DATA_DIR) $(CONFIG_DIR)
# 	@touch $(CONFIG_DIR)/config.toml
# 	@echo "[+] Setting ownership to UID 10001..."
# 	@sudo chown -R 10001:10001 $(DATA_DIR) $(CONFIG_DIR)
# 	@echo "[+] Starting RustFS container..."
# 	docker compose up -d

# start: up

# stop:
# 	docker compose down

# restart: stop up

# logs:
# 	docker compose logs -f

# status:
# 	docker ps | grep rustfs || true

# clean:
# 	docker compose down -v
# 	sudo rm -rf ${DATA_DIR}

# backup:
# 	tar czvf rustfs-backup-$(shell date +%Y%m%d_%H%M%S).tar.gz -C ${DATA_DIR} .

# restore:
# 	@echo "Restoring from backup. Make sure to stop container first!"
# 	@echo "Usage: make restore BACKUP_FILE=<path>"
# 	tar xzvf ${BACKUP_FILE} -C ${DATA_DIR}

# # Build RustFS binary from source (optional)
# binary:
# 	@if [ ! -d rustfs-src ]; then \
# 		echo "[+] Cloning RustFS source..."; \
# 		git clone https://github.com/rustfs/rustfs.git rustfs-src; \
# 	fi
# 	cd rustfs-src && cargo build --release
# 	cp rustfs-src/target/release/rustfs ./rustfs-binary

# # Rebuild binary and Docker image
# rebuild:
# 	rm -f ./rustfs-binary
# 	make binary
# 	make build

# ------------------------------------------
# Load .env if it exists, but don't fail if missing
-include .env

# Default directories if not set in env
DATA_DIR ?= ./data
CONFIG_DIR ?= ./config

# Default image and ports
RUSTFS_IMAGE ?= rustfs/rustfs:latest
RUSTFS_PORT ?= 8080
RUSTFS_METRICS_PORT ?= 9090
RUSTFS_WEB_PORT ?= 9001
RUSTFS_ACCESS_KEY ?= rustfsadmin
RUSTFS_SECRET_KEY ?= rustfsadmin

.PHONY: help build up start stop restart logs status clean backup restore binary rebuild

help:
	@echo "RustFS Docker Makefile"
	@echo "---------------------"
	@echo "make build       - build rustfs docker image (uses rustfs-binary)"
	@echo "make up          - start rustfs container"
	@echo "make start       - alias for 'make up'"
	@echo "make stop        - stop rustfs container"
	@echo "make restart     - restart container"
	@echo "make logs        - follow logs"
	@echo "make status      - show running container status"
	@echo "make clean       - remove container and volumes (dangerous)"
	@echo "make backup      - backup rustfs data"
	@echo "make restore     - restore rustfs data from backup"
	@echo "make binary      - build RustFS binary from source"
	@echo "make rebuild     - rebuild binary + Docker image"
	@echo ""

# Build RustFS Docker image
build:
	@if [ -f ./rustfs-binary ]; then \
		echo "[+] Using existing rustfs-binary"; \
	else \
		echo "[!] rustfs-binary not found. Skipping binary build, using prebuilt image."; \
	fi
	docker build -t ${RUSTFS_IMAGE} .

# Run Docker container
up:
	@echo "[+] Ensuring data and config directories exist..."
	@mkdir -p $(DATA_DIR) $(CONFIG_DIR)
	@touch $(CONFIG_DIR)/config.toml
	@echo "[+] Setting ownership to UID 10001..."
	@sudo chown -R 10001:10001 $(DATA_DIR) $(CONFIG_DIR)
	@echo "[+] Starting RustFS container..."
	docker compose up -d

start: up

stop:
	docker compose down

restart: stop up

logs:
	docker compose logs -f

status:
	docker ps | grep rustfs || true

clean:
	docker compose down -v
	sudo rm -rf $(DATA_DIR)

backup:
	tar czvf rustfs-backup-$(shell date +%Y%m%d_%H%M%S).tar.gz -C $(DATA_DIR) .

restore:
	@echo "Restoring from backup. Make sure to stop container first!"
	@echo "Usage: make restore BACKUP_FILE=<path>"
	tar xzvf ${BACKUP_FILE} -C $(DATA_DIR)

# Build RustFS binary from source (optional, requires Rust/Cargo)
binary:
	@if ! command -v cargo >/dev/null 2>&1; then \
		echo "[!] Cargo not found. Install Rust/Cargo first, or skip binary build to use prebuilt Docker image."; \
		exit 1; \
	fi
	@if [ ! -d rustfs-src ]; then \
		echo "[+] Cloning RustFS source..."; \
		git clone https://github.com/rustfs/rustfs.git rustfs-src; \
	fi
	cd rustfs-src && cargo build --release
	cp rustfs-src/target/release/rustfs ./rustfs-binary

# Rebuild binary and Docker image
rebuild:
	rm -f ./rustfs-binary
	make binary
	make build
