include .env

# Default directories if not set in env
DATA_DIR ?= ./data

.PHONY: help up start stop restart logs status clean backup restore

help:
	@echo "RustFS Docker Makefile"
	@echo "---------------------"
	@echo "make up          - start rustfs container"
	@echo "make start       - alias for 'make up'"
	@echo "make stop        - stop rustfs container"
	@echo "make restart     - restart container"
	@echo "make logs        - follow logs"
	@echo "make status      - show running container status"
	@echo "make clean       - remove container and volumes (dangerous)"
	@echo "make backup      - backup rustfs data"
	@echo "make restore     - restore rustfs data from backup"
	@echo ""

# Run Docker container
up:
	@echo "[+] Ensuring data directory exists..."
	@mkdir -p $(DATA_DIR)
	@echo "[+] Setting ownership to UID 10001..."
	@sudo chown -R 10001:10001 $(DATA_DIR) 2>/dev/null || true
	@echo "[+] Starting RustFS container..."
	docker compose up -d
	@echo ""
	@echo "✓ RustFS is starting!"
	@echo "  Web Console: http://localhost:$(RUSTFS_WEB_PORT)"
	@echo "  API Endpoint: http://localhost:$(RUSTFS_PORT)"
	@echo "  Default credentials: $(RUSTFS_ROOT_USER) / $(RUSTFS_ROOT_PASSWORD)"
	@echo ""

start: up

stop:
	@echo "[+] Stopping RustFS container..."
	docker compose down

restart: stop up

logs:
	docker compose logs -f

status:
	@docker ps | grep rustfs || echo "RustFS container is not running"

clean:
	@echo "[!] WARNING: This will delete all data and volumes!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		sudo rm -rf $(DATA_DIR); \
		echo "✓ Cleaned up"; \
	else \
		echo "Cancelled"; \
	fi

backup:
	@echo "[+] Creating backup..."
	tar czvf rustfs-backup-$(shell date +%Y%m%d_%H%M%S).tar.gz -C $(DATA_DIR) .
	@echo "✓ Backup created"

restore:
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "[!] Usage: make restore BACKUP_FILE=<path>"; \
		exit 1; \
	fi
	@echo "[+] Restoring from backup. Make sure to stop container first!"
	tar xzvf $(BACKUP_FILE) -C $(DATA_DIR)
	@echo "✓ Restore complete"
