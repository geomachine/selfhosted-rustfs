# RustFS with Nginx Reverse Proxy

Production-ready Docker setup for RustFS object storage with Nginx reverse proxy.

## Architecture

```
Internet → Nginx (80/443) → RustFS (internal 9000/9001)
```

- RustFS is NOT exposed to the internet directly
- Nginx handles all external traffic
- SSL/TLS termination at Nginx
- Optional basic auth for console

## Quick Start

```bash
# Start everything
make up

# View logs
make logs

# Stop everything
make stop
```

## Access

- **Web Console**: http://localhost/console/
- **API Endpoint**: http://localhost/api/
- **S3 Endpoint**: http://localhost/s3/
- **Health Check**: http://localhost/health
- **Default Credentials**: `rustfsadmin` / `rustfsadmin`

## Configuration

Edit `.env` file:

```bash
# RustFS credentials
RUSTFS_ROOT_USER=rustfsadmin
RUSTFS_ROOT_PASSWORD=rustfsadmin

# Nginx ports
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443

# Domain (for production)
DOMAIN_NAME=storage.yourdomain.com
```

## Nginx Configuration

### Upstreams

Defined in `nginx/conf.d/rustfs.conf`:

```nginx
upstream rustfs_api {
    server rustfs:9000;
    keepalive 32;
}

upstream rustfs_console {
    server rustfs:9001;
    keepalive 32;
}
```

### Routes

- `/api/` → RustFS API (port 9000)
- `/s3/` → RustFS S3 API (port 9000)
- `/console/` → RustFS Web Console (port 9001)
- `/` → Redirects to `/console/`
- `/health` → Nginx health check

## Enable HTTPS

### Option 1: Self-signed certificate (for testing)

```bash
make ssl-setup
```

Then uncomment the HTTPS server block in `nginx/conf.d/rustfs.conf`.

### Option 2: Let's Encrypt (for production)

1. Install certbot on your EC2 instance:
   ```bash
   sudo apt install certbot python3-certbot-nginx
   ```

2. Get certificate:
   ```bash
   sudo certbot --nginx -d storage.yourdomain.com
   ```

3. Update `nginx/conf.d/rustfs.conf` to use the Let's Encrypt certificates:
   ```nginx
   ssl_certificate /etc/letsencrypt/live/storage.yourdomain.com/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/storage.yourdomain.com/privkey.pem;
   ```

4. Mount certificates in `docker-compose.yml`:
   ```yaml
   volumes:
     - /etc/letsencrypt:/etc/letsencrypt:ro
   ```

## Add Basic Auth to Console

1. Create password file:
   ```bash
   sudo apt install apache2-utils
   htpasswd -c nginx/.htpasswd admin
   ```

2. Uncomment in `nginx/conf.d/rustfs.conf`:
   ```nginx
   auth_basic "RustFS Console";
   auth_basic_user_file /etc/nginx/.htpasswd;
   ```

3. Mount in `docker-compose.yml`:
   ```yaml
   volumes:
     - ./nginx/.htpasswd:/etc/nginx/.htpasswd:ro
   ```

## Deployment to EC2

1. **Copy files to EC2**:
   ```bash
   scp -r * ubuntu@your-ec2-ip:~/rustfs/
   ```

2. **SSH and start**:
   ```bash
   ssh ubuntu@your-ec2-ip
   cd rustfs
   make up
   ```

3. **Security Group**: Only open port 80 and 443
   - Port 80 (HTTP)
   - Port 443 (HTTPS)
   - Port 22 (SSH)
   
   **Do NOT open 9000 or 9001!**

4. **Point your domain** to EC2 public IP

5. **Setup SSL** with Let's Encrypt (see above)

## Available Commands

```bash
make up           # Start all containers
make stop         # Stop all containers
make restart      # Restart all containers
make logs         # Follow all logs
make logs-nginx   # Follow nginx logs only
make logs-rustfs  # Follow rustfs logs only
make status       # Show container status
make backup       # Backup data directory
make restore      # Restore from backup
make ssl-setup    # Create self-signed SSL cert
make clean        # Remove everything (dangerous!)
```

## Data Persistence

All buckets and objects are stored in `./data` directory and persist across container restarts.

The volume is correctly mounted to `/data` where RustFS stores its data in `/data/.rustfs.sys`.

## Troubleshooting

**Nginx won't start?**
- Check if port 80/443 are already in use: `sudo netstat -tulpn | grep -E ':80|:443'`
- Check nginx logs: `make logs-nginx`

**RustFS won't start?**
- Check rustfs logs: `make logs-rustfs`
- Verify data directory permissions: `ls -la data/`

**Can't access console?**
- Check if containers are running: `make status`
- Test health endpoint: `curl http://localhost/health`
- Check nginx config: `docker exec rustfs-nginx nginx -t`

**502 Bad Gateway?**
- RustFS container might not be ready yet, wait 10 seconds
- Check if rustfs is running: `docker ps | grep rustfs`
- Check network: `docker network inspect rustfs_rustfs-network`
