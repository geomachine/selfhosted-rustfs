# Quick Start Guide (Dual Domain Setup)

## On Your VPS

### 1. Edit .env file

```bash
nano .env
```

Change these lines:
```bash
CONSOLE_DOMAIN=rustfs.yourdomain.com        # ← Change to your console subdomain
API_DOMAIN=api-rustfs.yourdomain.com        # ← Change to your API subdomain
RUSTFS_ROOT_PASSWORD=rustfsadmin            # ← Change to a strong password
```

Save and exit (Ctrl+X, then Y, then Enter)

### 2. Run the automated SSL setup

```bash
./setup-ssl.sh
```

This will:
- Install certbot
- Obtain SSL certificates for BOTH domains
- Update nginx configuration with your domains
- Start all services

### 3. Access your RustFS

**Web Console:**
```
https://rustfs.yourdomain.com/
```

**API Endpoint (for S3 clients):**
```
https://api-rustfs.yourdomain.com/
```

Login with credentials from your `.env` file.

## Architecture

```
Internet
   │
   ├─→ rustfs.yourdomain.com (HTTPS) → Nginx → RustFS Console (9001)
   │
   └─→ api-rustfs.yourdomain.com (HTTPS) → Nginx → RustFS API (9000)
```

## S3 Client Configuration

When using S3 clients (AWS CLI, boto3, etc.), use:

```bash
Endpoint: https://api-rustfs.yourdomain.com
Access Key: rustfsadmin (or your custom username)
Secret Key: rustfsadmin (or your custom password)
```

Example with AWS CLI:
```bash
aws configure set aws_access_key_id rustfsadmin
aws configure set aws_secret_access_key rustfsadmin
aws s3 ls --endpoint-url https://api-rustfs.yourdomain.com
```

## Common Commands

```bash
make logs          # View logs
make status        # Check if running
make restart       # Restart services
make backup        # Backup your data
make stop          # Stop services
```

## Troubleshooting

**Can't access the console?**
```bash
# Check if containers are running
make status

# Check logs
make logs

# Test health endpoints
curl https://rustfs.yourdomain.com/health
curl https://api-rustfs.yourdomain.com/health
```

**SSL certificate error?**
- Wait 2-3 minutes for DNS propagation
- Verify your subdomains point to VPS IP:
  ```bash
  dig rustfs.yourdomain.com
  dig api-rustfs.yourdomain.com
  ```
- Check firewall allows port 80 and 443

**Need help?**
Read the full [DEPLOYMENT.md](DEPLOYMENT.md) guide.
