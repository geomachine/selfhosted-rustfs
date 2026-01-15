# Local Development Guide

Guide for developing and testing RustFS locally without SSL certificates or production infrastructure.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Development vs Production](#development-vs-production)
- [Common Tasks](#common-tasks)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

## Overview

Development mode allows you to run RustFS locally without:
- SSL certificates
- Domain names
- Nginx reverse proxy
- Production server

This is ideal for:
- Testing features
- Development
- Learning RustFS
- Quick experiments

## Prerequisites

### Required

- Docker 20.10+
- Docker Compose 2.0+
- Git

### Optional

- AWS CLI (for S3 API testing)
- Python with boto3 (for S3 API testing)
- Node.js with AWS SDK (for S3 API testing)

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/selfhosted-rustfs.git
cd selfhosted-rustfs
```

### 2. Start Development Mode

```bash
make dev
```

This will:
- Create data directory
- Set proper permissions
- Start RustFS container
- Expose ports 9000 and 9001

### 3. Access RustFS

- **Web Console**: http://localhost:9001/rustfs/console/
- **API Endpoint**: http://localhost:9000/

**Default Credentials:**
- Username: `rustfsadmin`
- Password: `rustfsadmin`

### 4. Stop Development Mode

```bash
make dev-stop
```

## Development vs Production

| Feature | Development | Production |
|---------|-------------|------------|
| SSL/TLS | ❌ No | ✅ Yes |
| Nginx | ❌ No | ✅ Yes |
| Domain Names | ❌ Not needed | ✅ Required |
| Port Exposure | ✅ Direct (9000, 9001) | ❌ Internal only |
| Setup Time | ⚡ 30 seconds | ⏱️ 5-10 minutes |
| Use Case | Testing, Development | Production deployment |

### Architecture Comparison

**Development Mode:**
```
Your Browser
   │
   ├─→ localhost:9001 → RustFS Console
   └─→ localhost:9000 → RustFS API
```

**Production Mode:**
```
Internet
   │
   ├─→ rustfs.yourdomain.com (HTTPS) → Nginx → RustFS Console
   └─→ api-rustfs.yourdomain.com (HTTPS) → Nginx → RustFS API
```

## Common Tasks

### Starting and Stopping

```bash
# Start development mode
make dev

# Stop development mode
make dev-stop

# View logs
make logs-rustfs

# Check status
docker ps | grep rustfs
```

### Accessing the Console

1. Open browser: http://localhost:9001/rustfs/console/
2. Login with default credentials
3. Create buckets, upload files, etc.

### Testing S3 API

#### Using AWS CLI

```bash
# Configure AWS CLI
aws configure set aws_access_key_id rustfsadmin
aws configure set aws_secret_access_key rustfsadmin
aws configure set default.region us-east-1

# List buckets
aws s3 ls --endpoint-url http://localhost:9000

# Create bucket
aws s3 mb s3://test-bucket --endpoint-url http://localhost:9000

# Upload file
echo "Hello RustFS" > test.txt
aws s3 cp test.txt s3://test-bucket/ --endpoint-url http://localhost:9000

# List objects
aws s3 ls s3://test-bucket/ --endpoint-url http://localhost:9000

# Download file
aws s3 cp s3://test-bucket/test.txt downloaded.txt --endpoint-url http://localhost:9000
```

#### Using Python (boto3)

```python
import boto3

# Create S3 client
s3 = boto3.client(
    's3',
    endpoint_url='http://localhost:9000',
    aws_access_key_id='rustfsadmin',
    aws_secret_access_key='rustfsadmin',
    region_name='us-east-1'
)

# List buckets
response = s3.list_buckets()
print('Buckets:', [b['Name'] for b in response['Buckets']])

# Create bucket
s3.create_bucket(Bucket='test-bucket')

# Upload file
s3.put_object(
    Bucket='test-bucket',
    Key='test.txt',
    Body=b'Hello RustFS'
)

# List objects
response = s3.list_objects_v2(Bucket='test-bucket')
print('Objects:', [obj['Key'] for obj in response.get('Contents', [])])

# Download file
response = s3.get_object(Bucket='test-bucket', Key='test.txt')
content = response['Body'].read()
print('Content:', content.decode())
```

#### Using cURL

```bash
# Health check
curl http://localhost:9000/health

# List buckets (requires authentication)
curl -X GET http://localhost:9000/ \
  -H "Authorization: AWS4-HMAC-SHA256 ..."
```

### Changing Credentials

Edit `.env` file:

```bash
nano .env
```

Change:
```bash
RUSTFS_ROOT_USER=myusername
RUSTFS_ROOT_PASSWORD=mypassword
```

Restart:
```bash
make dev-stop
make dev
```

### Viewing Logs

```bash
# Follow logs in real-time
make logs-rustfs

# View last 50 lines
docker logs rustfs --tail 50

# View logs with timestamps
docker logs rustfs --timestamps

# Search logs for errors
docker logs rustfs 2>&1 | grep ERROR
```

### Inspecting Data

```bash
# View data directory
ls -la data/

# View RustFS system files
ls -la data/.rustfs.sys/

# Check disk usage
du -sh data/
```

## Testing

### Manual Testing

1. **Create Bucket**
   - Open console: http://localhost:9001/rustfs/console/
   - Click "Create Bucket"
   - Enter name: `test-bucket`
   - Click "Create"

2. **Upload File**
   - Select bucket
   - Click "Upload"
   - Choose file
   - Click "Upload"

3. **Download File**
   - Click on file
   - Click "Download"

4. **Delete File**
   - Select file
   - Click "Delete"

### Automated Testing

Create a test script:

```bash
#!/bin/bash
set -e

ENDPOINT="http://localhost:9000"
BUCKET="test-bucket-$(date +%s)"

echo "Testing RustFS..."

# Create bucket
aws s3 mb s3://$BUCKET --endpoint-url $ENDPOINT
echo "✓ Bucket created"

# Upload file
echo "test content" > test.txt
aws s3 cp test.txt s3://$BUCKET/ --endpoint-url $ENDPOINT
echo "✓ File uploaded"

# List objects
aws s3 ls s3://$BUCKET/ --endpoint-url $ENDPOINT
echo "✓ File listed"

# Download file
aws s3 cp s3://$BUCKET/test.txt downloaded.txt --endpoint-url $ENDPOINT
echo "✓ File downloaded"

# Verify content
if diff test.txt downloaded.txt; then
    echo "✓ Content verified"
else
    echo "✗ Content mismatch"
    exit 1
fi

# Cleanup
aws s3 rb s3://$BUCKET --force --endpoint-url $ENDPOINT
rm test.txt downloaded.txt
echo "✓ Cleanup complete"

echo "All tests passed!"
```

Run:
```bash
chmod +x test-rustfs.sh
./test-rustfs.sh
```

## Troubleshooting

### Container Won't Start

**Check logs:**
```bash
docker logs rustfs
```

**Common issues:**
- Port 9000 or 9001 already in use
- Data directory permission issues
- Docker not running

**Solutions:**
```bash
# Check what's using the ports
sudo lsof -i :9000
sudo lsof -i :9001

# Fix permissions
sudo chown -R 10001:10001 data/

# Restart Docker
sudo systemctl restart docker
```

### Can't Access Console

**Verify container is running:**
```bash
docker ps | grep rustfs
```

**Check if ports are exposed:**
```bash
docker port rustfs
```

**Test with curl:**
```bash
curl http://localhost:9001/rustfs/console/
```

### Authentication Errors

**Verify credentials:**
```bash
cat .env | grep RUSTFS_ROOT
```

**Check RustFS logs:**
```bash
docker logs rustfs | grep -i auth
```

### Data Not Persisting

**Check volume mount:**
```bash
docker inspect rustfs | grep -A 10 Mounts
```

**Verify data directory:**
```bash
ls -la data/.rustfs.sys/
```

### Performance Issues

**Check resource usage:**
```bash
docker stats rustfs
```

**Increase Docker resources:**
- Docker Desktop → Settings → Resources
- Increase CPU and Memory

## Development Workflow

### Making Changes

1. **Stop services**
   ```bash
   make dev-stop
   ```

2. **Make changes to configuration**
   ```bash
   nano .env
   # or
   nano docker-compose.local.yml
   ```

3. **Restart services**
   ```bash
   make dev
   ```

4. **Test changes**
   ```bash
   curl http://localhost:9000/health
   ```

### Testing Different Versions

```bash
# Edit docker-compose.local.yml
nano docker-compose.local.yml

# Change image version
# image: rustfs/rustfs:latest
# to
# image: rustfs/rustfs:1.0.0

# Restart
make dev-stop
make dev
```

### Debugging

Enable debug logging:

```bash
# Edit docker-compose.local.yml
nano docker-compose.local.yml
```

Add to environment:
```yaml
environment:
  - RUST_LOG=debug
```

Restart and view logs:
```bash
make dev-stop
make dev
make logs-rustfs
```

## Next Steps

After local development:

1. **Test thoroughly** - Ensure everything works locally
2. **Review production docs** - Read [DEPLOYMENT.md](DEPLOYMENT.md)
3. **Setup production** - Deploy to server with SSL
4. **Configure monitoring** - Setup health checks
5. **Enable backups** - Configure automated backups

## Resources

- [Main Documentation](README.md)
- [Production Deployment](DEPLOYMENT.md)
- [Contributing Guide](CONTRIBUTING.md)
- [RustFS Official Docs](https://docs.rustfs.com)

---

Happy developing! 🚀
