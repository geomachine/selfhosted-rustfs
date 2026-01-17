# RustFS Production Deployment Guide

Complete step-by-step guide for deploying RustFS with Nginx reverse proxy in production environments.

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Server Preparation](#server-preparation)
3. [DNS Configuration](#dns-configuration)
4. [Installation](#installation)
5. [SSL Configuration](#ssl-configuration)
6. [Post-Deployment](#post-deployment)
7. [Production Hardening](#production-hardening)
8. [Monitoring Setup](#monitoring-setup)

## Pre-Deployment Checklist

### Infrastructure Requirements

- [ ] Server with public IP address
- [ ] Minimum 2GB RAM, 2 CPU cores
- [ ] 50GB+ storage space
- [ ] Ubuntu 20.04+ or similar Linux distribution
- [ ] Root or sudo access

### Domain Requirements

- [ ] Two subdomains registered:
  - Console subdomain (e.g., `rustfs.yourdomain.com`)
  - API subdomain (e.g., `api-rustfs.yourdomain.com`)
- [ ] DNS A records pointing to server IP
- [ ] DNS propagation completed (check with `dig` or `nslookup`)

### Access Requirements

- [ ] SSH access to server
- [ ] Email address for Let's Encrypt notifications
- [ ] Firewall/Security Group access

## Server Preparation

### 1. Update System

```bash
sudo apt update
sudo apt upgrade -y
sudo reboot
```

### 2. Install Docker

```bash
# Install Docker
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Enable Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER

# Verify installation
docker --version
docker compose version
```

Log out and back in for group changes to take effect.

### 3. Install Additional Tools

```bash
sudo apt install -y git curl wget htop nano
```

### 4. Configure Firewall

```bash
# Install UFW if not present
sudo apt install -y ufw

# Configure firewall rules
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS

# Enable firewall
sudo ufw enable

# Verify rules
sudo ufw status
```

### 5. Stop Conflicting Services

```bash
# Check for services using ports 80/443
sudo lsof -i :80
sudo lsof -i :443

# Stop Apache if running
sudo systemctl stop apache2
sudo systemctl disable apache2

# Stop nginx if running (system-level)
sudo systemctl stop nginx
sudo systemctl disable nginx
```

## DNS Configuration

### 1. Create DNS Records

In your DNS provider (Cloudflare, Route53, etc.), create two A records:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | rustfs | YOUR_SERVER_IP | 300 |
| A | api-rustfs | YOUR_SERVER_IP | 300 |

### 2. Verify DNS Propagation

```bash
# Check console domain
dig rustfs.yourdomain.com +short

# Check API domain
dig api-rustfs.yourdomain.com +short

# Both should return your server IP
```

Wait for DNS propagation (usually 5-15 minutes, can take up to 48 hours).

## Installation

### 1. Clone Repository

```bash
cd ~
git clone https://github.com/yourusername/selfhosted-rustfs.git
cd selfhosted-rustfs
```

### 2. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit configuration
nano .env
```

Update these critical values:

```bash
# Your actual subdomains
CONSOLE_DOMAIN=rustfs.yourdomain.com
API_DOMAIN=api-rustfs.yourdomain.com

# Strong credentials (CHANGE THESE!)
RUSTFS_ACCESS_KEY=rustfsadmin
RUSTFS_SECRET_KEY=rustfsadmin

# Ports (usually keep defaults)
NGINX_HTTP_PORT=80
NGINX_HTTPS_PORT=443

# Data directory
DATA_DIR=./data
```

**Security Note**: Use a strong password with:
- Minimum 16 characters
- Mix of uppercase, lowercase, numbers, symbols
- No dictionary words

### 3. Verify Configuration

```bash
# Check environment file
cat .env

# Verify domains are correct
grep DOMAIN .env
```

## SSL Configuration

### 1. Run Automated Setup

```bash
# Make script executable
chmod +x setup-ssl.sh

# Run setup
./setup-ssl.sh
```

The script will prompt for:
- Your email address (for Let's Encrypt notifications)

### 2. Setup Process

The script will:
1. Install certbot
2. Create necessary directories
3. Stop nginx if running
4. Obtain SSL certificate for console domain
5. Obtain SSL certificate for API domain
6. Update nginx configuration with your domains
7. Start all services

### 3. Verify SSL Certificates

```bash
# Check certificates
sudo certbot certificates

# Should show both domains with valid certificates
```

### 4. Test HTTPS Access

```bash
# Test console health
curl https://rustfs.yourdomain.com/health

# Test API health
curl https://api-rustfs.yourdomain.com/health

# Both should return "healthy"
```

## Post-Deployment

### 1. Verify Services

```bash
# Check running containers
docker ps

# Should see:
# - rustfs (RustFS container)
# - rustfs-nginx (Nginx container)

# Check container logs
docker logs rustfs --tail 50
docker logs rustfs-nginx --tail 50
```

### 2. Access Web Console

Open browser and navigate to:
```
https://rustfs.yourdomain.com/
```

Login with credentials from `.env` file.

### 3. Create Test Bucket

In the web console:
1. Click "Create Bucket"
2. Enter bucket name (e.g., `test-bucket`)
3. Click "Create"
4. Upload a test file

### 4. Test S3 API

```bash
# Configure AWS CLI
aws configure set aws_access_key_id your_admin_username
aws configure set aws_secret_access_key your_strong_password
aws configure set default.region us-east-1

# List buckets
aws s3 ls --endpoint-url https://api-rustfs.yourdomain.com

# Should show your test bucket
```

### 5. Configure Auto-Start

Services are already configured to auto-start with Docker. Verify:

```bash
# Check restart policy
docker inspect rustfs | grep -A 5 RestartPolicy
docker inspect rustfs-nginx | grep -A 5 RestartPolicy

# Should show: "Name": "unless-stopped"
```

## Production Hardening

### 1. Enable Basic Authentication for Console

```bash
# Install apache2-utils
sudo apt install -y apache2-utils

# Create password file
htpasswd -c nginx/.htpasswd admin

# Edit nginx configuration
nano nginx/conf.d/rustfs.conf
```

Uncomment these lines in the console location block:
```nginx
auth_basic "RustFS Console";
auth_basic_user_file /etc/nginx/.htpasswd;
```

Update `docker-compose.yml` to mount the password file:
```yaml
volumes:
  - ./nginx/.htpasswd:/etc/nginx/.htpasswd:ro
```

Restart nginx:
```bash
docker restart rustfs-nginx
```

### 2. Configure Fail2Ban (Optional)

```bash
# Install fail2ban
sudo apt install -y fail2ban

# Create nginx jail
sudo nano /etc/fail2ban/jail.d/nginx.conf
```

Add:
```ini
[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 5
bantime = 3600
```

Restart fail2ban:
```bash
sudo systemctl restart fail2ban
sudo fail2ban-client status
```

### 3. Setup Log Rotation

```bash
# Create logrotate config
sudo nano /etc/logrotate.d/rustfs
```

Add:
```
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    missingok
    delaycompress
    copytruncate
}
```

### 4. Configure Automated Backups

```bash
# Create backup script
sudo nano /usr/local/bin/backup-rustfs.sh
```

Add:
```bash
#!/bin/bash
set -e

BACKUP_DIR="/backups/rustfs"
RUSTFS_DIR="/home/ubuntu/selfhosted-rustfs"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Create backup
cd $RUSTFS_DIR
make backup

# Move to backup directory
mv rustfs-backup-*.tar.gz $BACKUP_DIR/rustfs-backup-$DATE.tar.gz

# Keep only last 30 days
find $BACKUP_DIR -name "rustfs-backup-*.tar.gz" -mtime +30 -delete

# Optional: Upload to S3
# aws s3 cp $BACKUP_DIR/rustfs-backup-$DATE.tar.gz s3://your-backup-bucket/

echo "Backup completed: rustfs-backup-$DATE.tar.gz"
```

Make executable:
```bash
sudo chmod +x /usr/local/bin/backup-rustfs.sh
```

Schedule daily backups:
```bash
sudo crontab -e
```

Add:
```
0 2 * * * /usr/local/bin/backup-rustfs.sh >> /var/log/rustfs-backup.log 2>&1
```

### 5. Setup SSL Auto-Renewal

Certbot automatically configures renewal. Verify:

```bash
# Check renewal timer
sudo systemctl status certbot.timer

# Test renewal (dry run)
sudo certbot renew --dry-run
```

Add nginx restart to renewal hook:
```bash
sudo nano /etc/letsencrypt/renewal-hooks/deploy/restart-nginx.sh
```

Add:
```bash
#!/bin/bash
docker restart rustfs-nginx
```

Make executable:
```bash
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/restart-nginx.sh
```

## Monitoring Setup

### 1. Health Check Monitoring

Create health check script:
```bash
nano ~/check-rustfs-health.sh
```

Add:
```bash
#!/bin/bash

CONSOLE_URL="https://rustfs.yourdomain.com/health"
API_URL="https://api-rustfs.yourdomain.com/health"
ALERT_EMAIL="your-email@example.com"

check_endpoint() {
    local url=$1
    local name=$2
    
    if ! curl -sf "$url" > /dev/null; then
        echo "$name is DOWN!" | mail -s "RustFS Alert: $name Down" $ALERT_EMAIL
        return 1
    fi
    return 0
}

check_endpoint "$CONSOLE_URL" "Console"
check_endpoint "$API_URL" "API"
```

Make executable and schedule:
```bash
chmod +x ~/check-rustfs-health.sh

# Add to crontab (every 5 minutes)
crontab -e
```

Add:
```
*/5 * * * * ~/check-rustfs-health.sh
```

### 2. Container Monitoring

```bash
# Install ctop for container monitoring
sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop

# Run ctop
ctop
```

### 3. Disk Space Monitoring

```bash
# Create disk space check script
nano ~/check-disk-space.sh
```

Add:
```bash
#!/bin/bash

THRESHOLD=80
CURRENT=$(df -h / | grep / | awk '{print $5}' | sed 's/%//g')
ALERT_EMAIL="your-email@example.com"

if [ "$CURRENT" -gt "$THRESHOLD" ]; then
    echo "Disk space is at ${CURRENT}%" | mail -s "RustFS Alert: Low Disk Space" $ALERT_EMAIL
fi
```

Make executable and schedule:
```bash
chmod +x ~/check-disk-space.sh

# Add to crontab (daily)
crontab -e
```

Add:
```
0 8 * * * ~/check-disk-space.sh
```

### 4. Log Monitoring

```bash
# View real-time logs
docker compose logs -f

# Check for errors
docker logs rustfs 2>&1 | grep ERROR
docker logs rustfs-nginx 2>&1 | grep error
```

## Verification Checklist

After deployment, verify:

- [ ] Both domains resolve to server IP
- [ ] SSL certificates are valid (no browser warnings)
- [ ] Console accessible at https://rustfs.yourdomain.com/
- [ ] API accessible at https://api-rustfs.yourdomain.com/
- [ ] Can login to console with credentials
- [ ] Can create buckets
- [ ] Can upload/download files
- [ ] Health endpoints return "healthy"
- [ ] Containers auto-restart on failure
- [ ] Backups are configured and working
- [ ] Monitoring is active
- [ ] Firewall is properly configured
- [ ] SSL auto-renewal is configured

## Rollback Procedure

If deployment fails:

```bash
# Stop services
make stop

# Remove containers
docker compose down -v

# Restore from backup (if applicable)
make restore BACKUP_FILE=backup.tar.gz

# Or start fresh
rm -rf data/
make up
```

## Support

If you encounter issues:

1. Check logs: `make logs`
2. Verify DNS: `dig your-domain.com`
3. Test SSL: `curl -v https://your-domain.com/health`
4. Review [Troubleshooting Guide](README.md#troubleshooting)
5. Open an issue on GitHub

## Next Steps

After successful deployment:

1. Change default credentials
2. Configure backups
3. Setup monitoring
4. Review security settings
5. Test disaster recovery procedure
6. Document your specific configuration
7. Train team members on usage

---

**Deployment Complete!** Your RustFS instance is now running in production.
