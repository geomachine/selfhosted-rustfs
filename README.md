# RustFS Object Storage with Nginx Reverse Proxy

Production-ready deployment of RustFS S3-compatible object storage with Nginx reverse proxy, SSL/TLS encryption, and dual-domain architecture.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Usage](#usage)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Backup & Recovery](#backup--recovery)
- [Contributing](#contributing)
- [License](#license)

## Documentation

- **[README.md](README.md)** - This file, main documentation
- **[QUICKSTART.md](QUICKSTART.md)** - Get started in 5 minutes
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Local development guide
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Production deployment guide
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines
- **[CHANGELOG.md](CHANGELOG.md)** - Version history

## Overview

This project provides a complete Docker-based deployment solution for RustFS, a high-performance S3-compatible object storage system written in Rust. The setup includes:

- **RustFS**: Core object storage engine
- **Nginx**: Reverse proxy with SSL/TLS termination
- **Let's Encrypt**: Automated SSL certificate management
- **Docker Compose**: Container orchestration
- **Dual Domain Setup**: Separate domains for console and API

## Architecture

```
Internet
   │
   ├─→ rustfs.yourdomain.com (HTTPS:443)
   │      │
   │      └─→ Nginx Reverse Proxy
   │             │
   │             └─→ RustFS Console (Internal:9001)
   │
   └─→ api-rustfs.yourdomain.com (HTTPS:443)
          │
          └─→ Nginx Reverse Proxy
                 │
                 └─→ RustFS API (Internal:9000)
```

### Network Flow

1. **External Traffic**: All external traffic hits Nginx on ports 80/443
2. **SSL Termination**: Nginx handles SSL/TLS encryption
3. **Internal Routing**: Nginx proxies requests to RustFS containers
4. **Data Persistence**: All data stored in mounted volumes

### Security Model

- RustFS ports (9000, 9001) are **NOT** exposed to the internet
- Only Nginx ports (80, 443) are publicly accessible
- SSL/TLS encryption for all external traffic
- Optional basic authentication for console access

## Features

- ✅ **S3 Compatible**: Full S3 API compatibility
- ✅ **SSL/TLS**: Automated Let's Encrypt certificates
- ✅ **Dual Domain**: Separate console and API endpoints
- ✅ **Persistent Storage**: Data survives container restarts
- ✅ **Auto-Restart**: Containers restart on failure
- ✅ **Health Checks**: Built-in health monitoring endpoints
- ✅ **Nginx Reverse Proxy**: Production-grade request handling
- ✅ **Docker Compose**: Simple deployment and management
- ✅ **Automated Setup**: One-command SSL configuration

## Prerequisites

### System Requirements

- **OS**: Ubuntu 20.04+ (or similar Linux distribution)
- **RAM**: Minimum 2GB, recommended 4GB+
- **Storage**: Minimum 20GB free space
- **CPU**: 2+ cores recommended

### Software Requirements

- Docker 20.10+
- Docker Compose 2.0+
- Git
- OpenSSL
- Certbot (installed by setup script)

### Network Requirements

- Public IP address
- Two DNS A records pointing to your server:
  - `rustfs.yourdomain.com` → Your server IP
  - `api-rustfs.yourdomain.com` → Your server IP
- Firewall/Security Group allowing:
  - Port 22 (SSH)
  - Port 80 (HTTP)
  - Port 443 (HTTPS)

## Quick Start

### Local Development (No SSL)

For local testing without SSL certificates:

```bash
# 1. Clone repository
git clone https://github.com/Tresorraum/selfhosted-rustfs.git
cd selfhosted-rustfs

# 2. Start in development mode
make dev
```

Access:
- **Web Console**: http://localhost:9001/rustfs/console/
- **API Endpoint**: http://localhost:9000/

Default credentials: `rustfsadmin` / `rustfsadmin`

### Production Deployment (With SSL)

For production deployment with SSL certificates:

#### 1. Clone Repository

```bash
git clone https://github.com/Tresorraum/selfhosted-rustfs.git
cd selfhosted-rustfs
```

#### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

Update these values:
```bash
CONSOLE_DOMAIN=rustfs.yourdomain.com
API_DOMAIN=api-rustfs.yourdomain.com
RUSTFS_ROOT_USER=yourusername
RUSTFS_ROOT_PASSWORD=your-strong-password
```

#### 3. Run Automated Setup

```bash
chmod +x setup-ssl.sh
./setup-ssl.sh
```

The script will:
- Install certbot
- Obtain SSL certificates for both domains
- Update nginx configuration
- Start all services

#### 4. Access Your RustFS

- **Web Console**: https://rustfs.yourdomain.com/
- **API Endpoint**: https://api-rustfs.yourdomain.com/

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `CONSOLE_DOMAIN` | Domain for web console | `rustfs.yourdomain.com` | Yes |
| `API_DOMAIN` | Domain for API endpoint | `api-rustfs.yourdomain.com` | Yes |
| `RUSTFS_ROOT_USER` | Admin username | `rustfsadmin` | Yes |
| `RUSTFS_ROOT_PASSWORD` | Admin password | `rustfsadmin` | Yes |
| `DATA_DIR` | Data storage path | `./data` | No |
| `NGINX_HTTP_PORT` | HTTP port | `80` | No |
| `NGINX_HTTPS_PORT` | HTTPS port | `443` | No |

### Directory Structure

```
selfhosted-rustfs/
├── .env                    # Environment configuration
├── .env.example            # Example environment file
├── docker-compose.yml      # Docker services definition
├── Makefile               # Management commands
├── setup-ssl.sh           # SSL setup automation
├── nginx/
│   ├── nginx.conf         # Main nginx configuration
│   ├── conf.d/
│   │   └── rustfs.conf    # RustFS-specific nginx config
│   └── ssl/               # SSL certificates (auto-generated)
├── data/                  # Persistent data storage
├── certbot/               # Let's Encrypt challenge files
└── docs/                  # Additional documentation
```

## Deployment

### Local Development

For local development without SSL certificates:

```bash
# Start in development mode (RustFS only, no nginx)
make dev

# View logs
make logs-rustfs

# Stop development services
make dev-stop
```

**Access:**
- Web Console: http://localhost:9001/rustfs/console/
- API Endpoint: http://localhost:9000/

**Note:** Development mode exposes RustFS ports directly without nginx reverse proxy.

### Production Deployment

#### AWS EC2

1. **Launch EC2 Instance**
   - AMI: Ubuntu 22.04 LTS
   - Instance Type: t3.medium or larger
   - Storage: 50GB+ EBS volume

2. **Configure Security Group**
   ```
   Inbound Rules:
   - SSH (22) from your IP
   - HTTP (80) from 0.0.0.0/0
   - HTTPS (443) from 0.0.0.0/0
   ```

3. **Install Docker**
   ```bash
   sudo apt update
   sudo apt install -y docker.io docker-compose
   sudo systemctl enable docker
   sudo usermod -aG docker ubuntu
   ```

4. **Deploy Application**
   ```bash
   git clone <repository-url>
   cd selfhosted-rustfs
   cp .env.example .env
   nano .env  # Configure your domains
   ./setup-ssl.sh
   ```

#### DigitalOcean Droplet

1. **Create Droplet**
   - Image: Ubuntu 22.04
   - Plan: Basic ($12/month or higher)
   - Add your SSH key

2. **Configure Firewall**
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

3. **Follow production deployment steps above**

#### Other Cloud Providers

The deployment process is similar for:
- Google Cloud Platform (GCE)
- Microsoft Azure (VM)
- Linode
- Vultr
- Hetzner

Ensure ports 80 and 443 are open in your cloud provider's firewall.

## Usage

### Web Console

Access the web console at `https://rustfs.yourdomain.com/`

**Features:**
- Create and manage buckets
- Upload/download files
- View storage statistics
- Manage access keys
- Configure bucket policies

### S3 API

Use the API endpoint at `https://api-rustfs.yourdomain.com/`

#### AWS CLI Configuration

```bash
aws configure set aws_access_key_id your-username
aws configure set aws_secret_access_key your-password
aws configure set default.region us-east-1

# List buckets
aws s3 ls --endpoint-url https://api-rustfs.yourdomain.com

# Create bucket
aws s3 mb s3://my-bucket --endpoint-url https://api-rustfs.yourdomain.com

# Upload file
aws s3 cp file.txt s3://my-bucket/ --endpoint-url https://api-rustfs.yourdomain.com

# Download file
aws s3 cp s3://my-bucket/file.txt . --endpoint-url https://api-rustfs.yourdomain.com
```

#### Python (boto3)

```python
import boto3

s3 = boto3.client(
    's3',
    endpoint_url='https://api-rustfs.yourdomain.com',
    aws_access_key_id='your-username',
    aws_secret_access_key='your-password',
    region_name='us-east-1'
)

# List buckets
response = s3.list_buckets()
print(response['Buckets'])

# Upload file
s3.upload_file('local-file.txt', 'my-bucket', 'remote-file.txt')

# Download file
s3.download_file('my-bucket', 'remote-file.txt', 'downloaded-file.txt')
```

#### Node.js (AWS SDK)

```javascript
const AWS = require('aws-sdk');

const s3 = new AWS.S3({
    endpoint: 'https://api-rustfs.yourdomain.com',
    accessKeyId: 'your-username',
    secretAccessKey: 'your-password',
    s3ForcePathStyle: true,
    signatureVersion: 'v4'
});

// List buckets
s3.listBuckets((err, data) => {
    if (err) console.log(err);
    else console.log(data.Buckets);
});

// Upload file
const fs = require('fs');
const fileContent = fs.readFileSync('file.txt');

s3.putObject({
    Bucket: 'my-bucket',
    Key: 'file.txt',
    Body: fileContent
}, (err, data) => {
    if (err) console.log(err);
    else console.log('File uploaded successfully');
});
```

## Maintenance

### Available Commands

#### Production Commands

```bash
# Start services (production with nginx + SSL)
make up

# Stop services
make stop

# Restart services
make restart

# View all logs
make logs

# View nginx logs only
make logs-nginx

# View rustfs logs only
make logs-rustfs
```

#### Development Commands

```bash
# Start in development mode (no SSL, direct access)
make dev

# Stop development services
make dev-stop

# View logs
make logs-rustfs
```

#### Maintenance Commands

```bash
# Check container status
make status

# Create backup
make backup

# Restore from backup
make restore BACKUP_FILE=backup.tar.gz

# Generate self-signed SSL certificate (testing)
make ssl-setup

# Clean everything (WARNING: deletes data)
make clean
```

### Updating RustFS

```bash
# Pull latest image
docker compose pull rustfs

# Restart with new image
make restart

# Verify version
docker exec rustfs rustfs --version
```

### SSL Certificate Renewal

Certificates auto-renew via certbot. To manually renew:

```bash
sudo certbot renew
docker restart rustfs-nginx
```

### Monitoring

#### Health Checks

```bash
# Console health
curl https://rustfs.yourdomain.com/health

# API health
curl https://api-rustfs.yourdomain.com/health
```

#### Container Status

```bash
# Check running containers
docker ps

# Check container resource usage
docker stats

# View detailed container info
docker inspect rustfs
docker inspect rustfs-nginx
```

#### Logs

```bash
# Follow all logs
docker compose logs -f

# Last 100 lines
docker compose logs --tail 100

# Specific container
docker logs rustfs-nginx --tail 50
```

## Troubleshooting

### Common Issues

#### 1. Blank White Page on Console

**Symptom**: Console loads but shows blank page

**Solution**:
```bash
# Check nginx configuration
docker exec rustfs-nginx nginx -t

# Restart nginx
docker restart rustfs-nginx

# Check logs
docker logs rustfs-nginx --tail 50
```

#### 2. SSL Certificate Errors

**Symptom**: Browser shows SSL warning

**Solution**:
```bash
# Verify certificates exist
sudo ls -la /etc/letsencrypt/live/rustfs.yourdomain.com/

# Re-run setup
./setup-ssl.sh

# Check certificate expiry
sudo certbot certificates
```

#### 3. Port 80 Already in Use

**Symptom**: Cannot bind to port 80

**Solution**:
```bash
# Find what's using port 80
sudo lsof -i :80

# Stop Apache if running
sudo systemctl stop apache2
sudo systemctl disable apache2

# Retry setup
./setup-ssl.sh
```

#### 4. Container Keeps Restarting

**Symptom**: RustFS container in restart loop

**Solution**:
```bash
# Check logs
docker logs rustfs --tail 100

# Check data directory permissions
ls -la data/

# Fix permissions
sudo chown -R 10001:10001 data/

# Restart
make restart
```

#### 5. Cannot Access from Internet

**Symptom**: Works locally but not from internet

**Solution**:
```bash
# Check if ports are open
sudo ss -tulpn | grep -E ':80|:443'

# Verify firewall/security group
# AWS: Check EC2 Security Group
# UFW: sudo ufw status

# Test from server
curl -I https://rustfs.yourdomain.com/health
```

### Debug Mode

Enable verbose logging:

```bash
# Edit docker-compose.yml
# Add to rustfs environment:
environment:
  - RUST_LOG=debug

# Restart
make restart

# View logs
make logs-rustfs
```

## Security

### Best Practices

#### 1. Change Default Credentials

```bash
# Edit .env
nano .env

# Update these values
RUSTFS_ROOT_USER=your-secure-username
RUSTFS_ROOT_PASSWORD=your-strong-password-here

# Restart
make restart
```

#### 2. Enable Basic Auth for Console

```bash
# Install apache2-utils
sudo apt install apache2-utils

# Create password file
htpasswd -c nginx/.htpasswd admin

# Edit nginx/conf.d/rustfs.conf
# Uncomment these lines in console location block:
# auth_basic "RustFS Console";
# auth_basic_user_file /etc/nginx/.htpasswd;

# Add to docker-compose.yml nginx volumes:
# - ./nginx/.htpasswd:/etc/nginx/.htpasswd:ro

# Restart
make restart
```

#### 3. Firewall Configuration

```bash
# Using UFW (Ubuntu)
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable

# Verify
sudo ufw status
```

#### 4. Regular Updates

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker compose pull
make restart
```

#### 5. SSL/TLS Configuration

The nginx configuration includes:
- TLS 1.2 and 1.3 only
- Strong cipher suites
- HSTS headers
- Security headers (X-Frame-Options, etc.)

### Security Checklist

- [ ] Changed default credentials
- [ ] Enabled firewall (ports 22, 80, 443 only)
- [ ] SSL certificates installed and valid
- [ ] Regular backups configured
- [ ] Monitoring/alerting set up
- [ ] Basic auth enabled for console (optional)
- [ ] SSH key-based authentication only
- [ ] Fail2ban installed (optional)
- [ ] Regular security updates applied

## Backup & Recovery

### Manual Backup

```bash
# Create backup
make backup

# This creates: rustfs-backup-YYYYMMDD_HHMMSS.tar.gz
```

### Automated Backups

Create a backup script:

```bash
sudo nano /usr/local/bin/backup-rustfs.sh
```

```bash
#!/bin/bash
cd /path/to/selfhosted-rustfs
make backup

# Optional: Upload to S3
# aws s3 cp rustfs-backup-*.tar.gz s3://your-backup-bucket/

# Optional: Keep only last 7 days
find . -name "rustfs-backup-*.tar.gz" -mtime +7 -delete
```

Make executable and schedule:

```bash
sudo chmod +x /usr/local/bin/backup-rustfs.sh

# Add to crontab (daily at 2 AM)
sudo crontab -e
```

Add line:
```
0 2 * * * /usr/local/bin/backup-rustfs.sh
```

### Restore from Backup

```bash
# Stop services
make stop

# Restore data
make restore BACKUP_FILE=rustfs-backup-20260115_120000.tar.gz

# Start services
make up
```

### Disaster Recovery

1. **Provision new server**
2. **Install Docker and dependencies**
3. **Clone repository**
4. **Restore .env file**
5. **Restore data backup**
6. **Run setup**

```bash
# On new server
git clone <repository-url>
cd selfhosted-rustfs

# Copy .env from backup
cp /path/to/backup/.env .

# Restore data
make restore BACKUP_FILE=backup.tar.gz

# Run setup
./setup-ssl.sh
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Clone repository
git clone <repository-url>
cd selfhosted-rustfs

# Create development environment
cp .env.example .env.dev

# Start in development mode
docker compose up
```

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

RustFS itself is licensed under Apache 2.0 by RustFS, Inc.

## Support

- **Documentation**: [Full Documentation](./docs/)
- **Issues**: [GitHub Issues](https://github.com/yourusername/selfhosted-rustfs/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/selfhosted-rustfs/discussions)
- **RustFS Official**: [RustFS Documentation](https://docs.rustfs.com)

## Acknowledgments

- [RustFS](https://github.com/rustfs/rustfs) - The core object storage engine
- [Nginx](https://nginx.org/) - Reverse proxy server
- [Let's Encrypt](https://letsencrypt.org/) - Free SSL certificates
- [Docker](https://www.docker.com/) - Containerization platform

---

**Made with ❤️ for the self-hosting community**
