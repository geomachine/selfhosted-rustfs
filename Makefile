include .env

# Default directories if not set in env
DATA_DIR ?= ./data

.PHONY: help up start stop restart logs logs-nginx logs-rustfs status clean backup restore ssl-setup dev dev-stop

help:
	@echo "RustFS + Nginx Docker Makefile"
	@echo "-------------------------------"
	@echo "make up          - start rustfs + nginx containers (production)"
	@echo "make dev         - start rustfs only (local development)"
	@echo "make start       - alias for 'make up'"
	@echo "make stop        - stop all containers"
	@echo "make dev-stop    - stop development containers"
	@echo "make restart     - restart all containers"
	@echo "make logs        - follow all logs"
	@echo "make logs-nginx  - follow nginx logs only"
	@echo "make logs-rustfs - follow rustfs logs only"
	@echo "make status      - show running containers"
	@echo "make clean       - remove containers and volumes (dangerous)"
	@echo "make backup      - backup rustfs data"
	@echo "make restore     - restore rustfs data from backup"
	@echo "make ssl-setup   - create self-signed SSL certificate"
	@echo ""

# Run Docker containers
up:
	@echo "[+] Ensuring directories exist..."
	@mkdir -p $(DATA_DIR) nginx/conf.d nginx/ssl
	@echo "[+] Setting ownership to UID 10001..."
	@sudo chown -R 10001:10001 $(DATA_DIR) 2>/dev/null || true
	@echo "[+] Starting RustFS + Nginx containers..."
	docker compose up -d
	@echo ""
	@echo "✓ RustFS + Nginx are starting!"
	@echo "  Web Console: http://localhost/console/"
	@echo "  API Endpoint: http://localhost/api/"
	@echo "  S3 Endpoint: http://localhost/s3/"
	@echo "  Health Check: http://localhost/health"
	@echo "  Default credentials: $(RUSTFS_ROOT_USER) / $(RUSTFS_ROOT_PASSWORD)"
	@echo ""

start: up

# Local development (no nginx, direct access)
dev:
	@echo "[+] Ensuring data directory exists..."
	@mkdir -p $(DATA_DIR)
	@echo "[+] Setting ownership to UID 10001..."
	@sudo chown -R 10001:10001 $(DATA_DIR) 2>/dev/null || true
	@echo "[+] Starting RustFS (local development mode)..."
	docker compose -f docker-compose.local.yml up -d
	@echo ""
	@echo "✓ RustFS is starting (local development)!"
	@echo "  Web Console: http://localhost:9001/rustfs/console/"
	@echo "  API Endpoint: http://localhost:9000/"
	@echo "  Default credentials: $(RUSTFS_ROOT_USER) / $(RUSTFS_ROOT_PASSWORD)"
	@echo ""

dev-stop:
	@echo "[+] Stopping development containers..."
	docker compose -f docker-compose.local.yml down

stop:
	@echo "[+] Stopping all containers..."
	docker compose down

restart: stop up

logs:
	docker compose logs -f

logs-nginx:
	docker compose logs -f nginx

logs-rustfs:
	docker compose logs -f rustfs

status:
	@docker ps | grep -E 'rustfs|nginx' || echo "No containers running"

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

ssl-setup:
	@echo "[+] Creating self-signed SSL certificate..."
	@mkdir -p nginx/ssl
	@openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout nginx/ssl/key.pem \
		-out nginx/ssl/cert.pem \
		-subj "/C=US/ST=State/L=City/O=Organization/CN=$(DOMAIN_NAME)"
	@echo "✓ Self-signed certificate created in nginx/ssl/"
	@echo "  To enable HTTPS, uncomment the HTTPS server block in nginx/conf.d/rustfs.conf"
