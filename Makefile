include .env

# Default directories if not set in env
DATA_DIR ?= ./data

.PHONY: help up dev dev-stop stop logs fix-permissions backup restore clean

help:
	@echo "RustFS Docker Makefile"
	@echo "----------------------"
	@echo "make dev         - start rustfs (local development)"
	@echo "make dev-stop    - stop development containers"
	@echo "make up          - start rustfs + nginx (production)"
	@echo "make stop        - stop all containers"
	@echo "make logs        - follow logs"
	@echo "make fix-permissions - fix data directory permissions"
	@echo "make backup      - backup rustfs data"
	@echo "make restore     - restore rustfs data"
	@echo "make clean       - remove containers and data"
	@echo ""

# Fix permissions for macOS
fix-permissions:
	@echo "[+] Fixing data directory permissions..."
	@mkdir -p $(DATA_DIR)
	@sudo chown -R 10001:10001 $(DATA_DIR)
	@sudo chmod -R 777 $(DATA_DIR)
	@xattr -rc $(DATA_DIR) 2>/dev/null || true
	@echo "✓ Data directory permissions fixed: $(DATA_DIR)"

# Local development
dev: fix-permissions
	@echo "[+] Starting RustFS (local development)..."
	docker compose -f docker-compose.local.yml up -d
	@echo "✓ RustFS started!"
	@echo "  Web Console: http://localhost:9001/rustfs/console/"
	@echo "  API Endpoint: http://localhost:9000/"
	@echo "  Data: $(DATA_DIR)"

dev-stop:
	@echo "[+] Stopping development containers..."
	docker compose -f docker-compose.local.yml down

# Production with nginx
up: fix-permissions
	@echo "[+] Starting RustFS + Nginx..."
	@mkdir -p nginx/conf.d nginx/ssl
	docker compose up -d
	@echo "✓ RustFS + Nginx started!"
	@echo "  Web Console: http://localhost/console/"
	@echo "  API Endpoint: http://localhost/api/"

stop:
	@echo "[+] Stopping all containers..."
	docker compose down

logs:
	docker compose logs -f

# Backup and restore
backup:
	@echo "[+] Creating backup..."
	tar czvf rustfs-backup-$(shell date +%Y%m%d_%H%M%S).tar.gz -C $(DATA_DIR) .
	@echo "✓ Backup created"

restore:
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "[!] Usage: make restore BACKUP_FILE=<filename>"; \
		exit 1; \
	fi
	@echo "[+] Stopping containers..."
	@docker compose -f docker-compose.local.yml down 2>/dev/null || true
	@docker compose down 2>/dev/null || true
	@echo "[+] Restoring $(BACKUP_FILE)..."
	@echo "[!] This will overwrite existing data!"
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [ "$$REPLY" = "y" ] || [ "$$REPLY" = "Y" ]; then \
		sudo rm -rf $(DATA_DIR); \
		mkdir -p $(DATA_DIR); \
		sudo tar -xzf $(BACKUP_FILE) -C $(DATA_DIR) --no-same-owner; \
		$(MAKE) fix-permissions; \
		ls -la $(DATA_DIR)/; \
		echo "✓ Restore complete"; \
	fi

clean:
	@echo "[!] WARNING: This will delete all data!"
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [ "$$REPLY" = "y" ] || [ "$$REPLY" = "Y" ]; then \
		docker compose down -v; \
		sudo rm -rf $(DATA_DIR); \
		echo "✓ Cleaned up"; \
	fi