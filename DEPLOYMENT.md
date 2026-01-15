# RustFS Production Deployment Guide

Complete guide for deploying RustFS with Nginx reverse proxy and SSL on your VPS.

## Prerequisites

- VPS with Ubuntu (or similar)
- Domain/subdomain pointing to your VPS IP
- Docker and Docker Compose installed
- Ports 80 and 443 open (no need to open 9000/9001)

## Step-by-Step Deployment

### 1. Update Your Domain in .env

Edit `.env` file and replace `storage.yourdomain.com` with your actual subdomain:

```bash
nano .env
```

Change this line:
```bash
DOMAIN_NAME=storage.yourdomain.com
```

To your actual subdomain:
```bash
DOMAIN_NAME=storage.example.com
```

**Important:** Also change the default credentials!
```bash
RUSTFS_ROOT_USER=yourusername
RUSTFS_ROOT_PASSWORD=your-strong-password
```

### 2. Update Nginx Configuration

The nginx config file `nginx/conf.d/rustfs.conf` has the domain hardcoded in two places. You have two options:

**Option A: Use the automated setup script (recommended)**
```bash
./setup-ssl.sh
```

This script will:
- Install certbot
- Obtain SSL certificate from Let's Encrypt
- Update nginx configuration with your domain
- Start all services

**Option B: Manual setup**

Edit `nginx/conf.d/rustfs.conf` and replace all instances of `storage.yourdomain.com` with your actual subdomain:

```bash
sed -i 's/storage\.yourdomain\.com/storage.example.com/g' nginx/conf.d/rustfs.conf
```

Then obtain SSL certificate manually:
```bash
sudo apt update
sudo apt install certbot
sudo certbot certonly --standalone -d storage.example.com
```

### 3. Start Services

```bash
make up
```

### 4. Verify Everything Works

Check if containers are running:
```bash
make status
```

Check logs:
```bash
make logs
```

Test health endpoint:
```bash
curl https://storage.example.com/health
```

### 5. Access Your RustFS

- **Web Console**: https://storage.example.com/console/
- **API Endpoint**: https://storage.example.com/api/
- **S3 Endpoint**: https://storage.example.com/s3/

## Security Checklist

### ✅ Change Default Credentials

Edit `.env`:
```bash
RUSTFS_ROOT_USER=yourusername
RUSTFS_ROOT_PASSWORD=your-strong-password-here
```

Then restart:
```bash
make restart
```

### ✅ Add Basic Auth to Console (Optional but Recommended)

1. Install apache2-utils:
   ```bash
   sudo apt install apache2-utils
   ```

2. Create password file:
   ```bash
   htpasswd -c nginx/.htpasswd admin
   ```

3. Uncomment these lines in `nginx/conf.d/rustfs.conf` under the console location:
   ```nginx
   auth_basic "RustFS Console";
   auth_basic_user_file /etc/nginx/.htpasswd;
   ```

4. Add to docker-compose.yml nginx volumes:
   ```yaml
   - ./nginx/.htpasswd:/etc/nginx/.htpasswd:ro
   ```

5. Restart:
   ```bash
   make restart
   ```

### ✅ Firewall Configuration

Only allow these ports:
```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

**Do NOT open ports 9000 or 9001** - they should only be accessible internally via Docker network.

### ✅ SSL Certificate Auto-Renewal

Let's Encrypt certificates expire after 90 days. Set up auto-renewal:

```bash
sudo crontab -e
```

Add this line:
```
0 0 * * * certbot renew --quiet && docker compose -f /path/to/rustfs/docker-compose.yml restart nginx
```

## VPS Security Group / Firewall Rules

If using AWS EC2, DigitalOcean, or similar:

**Inbound Rules:**
- Port 22 (SSH) - Your IP only
- Port 80 (HTTP) - 0.0.0.0/0
- Port 443 (HTTPS) - 0.0.0.0/0

**Do NOT open:**
- Port 9000 (RustFS API) - internal only
- Port 9001 (RustFS Console) - internal only

## Backup Strategy

### Manual Backup
```bash
make backup
```

### Automated Daily Backups

Create a backup script:
```bash
nano /usr/local/bin/backup-rustfs.sh
```

```bash
#!/bin/bash
cd /path/to/rustfs
make backup
# Optional: Upload to S3 or another location
# aws s3 cp rustfs-backup-*.tar.gz s3://your-backup-bucket/
```

Make it executable:
```bash
chmod +x /usr/local/bin/backup-rustfs.sh
```

Add to crontab:
```bash
sudo crontab -e
```

```
0 2 * * * /usr/local/bin/backup-rustfs.sh
```

## Monitoring

### Check Container Status
```bash
make status
```

### View Logs
```bash
make logs          # All logs
make logs-nginx    # Nginx only
make logs-rustfs   # RustFS only
```

### Health Check Endpoint
```bash
curl https://storage.example.com/health
```

Set up monitoring with UptimeRobot, Pingdom, or similar to monitor this endpoint.

## Troubleshooting

### SSL Certificate Issues

**Problem:** Certificate not found
```bash
# Check if certificate exists
sudo ls -la /etc/letsencrypt/live/storage.example.com/

# If not, obtain it
sudo certbot certonly --standalone -d storage.example.com
```

**Problem:** Certificate expired
```bash
sudo certbot renew
make restart
```

### Nginx Issues

**Problem:** 502 Bad Gateway
```bash
# Check if RustFS is running
docker ps | grep rustfs

# Check RustFS logs
make logs-rustfs

# Restart everything
make restart
```

**Problem:** Nginx config error
```bash
# Test nginx config
docker exec rustfs-nginx nginx -t

# Check nginx logs
make logs-nginx
```

### RustFS Issues

**Problem:** Container keeps restarting
```bash
# Check logs
make logs-rustfs

# Check data directory permissions
ls -la data/

# Fix permissions
sudo chown -R 10001:10001 data/
```

**Problem:** Buckets disappear after restart
- This should be fixed with the current configuration
- Verify volume mount: `docker inspect rustfs | grep -A 10 Mounts`
- Should show `/data` mounted, not `/data/rustfs`

## Updating RustFS

```bash
# Pull latest image
docker compose pull rustfs

# Restart with new image
make restart
```

## Complete Teardown

To completely remove everything (including data):
```bash
make clean
```

**Warning:** This deletes all your buckets and objects!
