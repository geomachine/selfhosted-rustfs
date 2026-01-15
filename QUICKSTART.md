# Quick Start Guide

Get RustFS up and running in 5 minutes.

## Prerequisites

- Ubuntu 20.04+ server with public IP
- Two DNS A records pointing to your server:
  - `rustfs.yourdomain.com`
  - `api-rustfs.yourdomain.com`
- Ports 80 and 443 open in firewall

## Installation

### 1. Install Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

Log out and back in.

### 2. Clone and Configure

```bash
git clone https://github.com/yourusername/selfhosted-rustfs.git
cd selfhosted-rustfs
cp .env.example .env
nano .env
```

Update these lines:
```bash
CONSOLE_DOMAIN=rustfs.yourdomain.com
API_DOMAIN=api-rustfs.yourdomain.com
RUSTFS_ROOT_PASSWORD=your-strong-password
```

### 3. Run Setup

```bash
chmod +x setup-ssl.sh
./setup-ssl.sh
```

Enter your email when prompted.

## Access

- **Console**: https://rustfs.yourdomain.com/
- **API**: https://api-rustfs.yourdomain.com/

Login with credentials from `.env` file.

## Common Commands

```bash
make logs          # View logs
make status        # Check status
make restart       # Restart services
make backup        # Create backup
make stop          # Stop services
```

## Test S3 API

```bash
aws configure set aws_access_key_id your-username
aws configure set aws_secret_access_key your-password

aws s3 ls --endpoint-url https://api-rustfs.yourdomain.com
```

## Troubleshooting

**Blank page?**
```bash
docker restart rustfs-nginx
```

**SSL errors?**
```bash
sudo certbot certificates
./setup-ssl.sh
```

**Can't connect?**
- Check DNS: `dig rustfs.yourdomain.com`
- Check firewall: `sudo ufw status`
- Check logs: `make logs`

## Next Steps

1. Change default password
2. Create your first bucket
3. Setup automated backups
4. Review [full documentation](README.md)

---

Need help? Check the [Troubleshooting Guide](README.md#troubleshooting) or [open an issue](https://github.com/yourusername/selfhosted-rustfs/issues).
