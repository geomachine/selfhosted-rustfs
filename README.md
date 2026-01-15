# RustFS Docker Deployment

Simple Docker setup for running RustFS object storage using the official prebuilt image.

## Quick Start

```bash
# Start RustFS
make up

# View logs
make logs

# Stop RustFS
make stop
```

## Access

- **Web Console**: http://localhost:9001
- **API Endpoint**: http://localhost:9000
- **Default Credentials**: `rustfsadmin` / `rustfsadmin`

## Configuration

Edit `.env` file to customize:

```bash
# Ports
RUSTFS_PORT=9000
RUSTFS_WEB_PORT=9001

# Directories
DATA_DIR=./data
LOGS_DIR=./logs

# Credentials
RUSTFS_ROOT_USER=rustfsadmin
RUSTFS_ROOT_PASSWORD=rustfsadmin
```

## Data Persistence

All buckets and objects are stored in `./data` directory and persist across container restarts.

The volume is correctly mounted to `/data` inside the container where RustFS stores its data in `/data/.rustfs.sys`.

## Available Commands

```bash
make up          # Start RustFS container
make stop        # Stop RustFS container
make restart     # Restart container
make logs        # Follow logs
make status      # Show container status
make backup      # Backup data directory
make restore     # Restore from backup (BACKUP_FILE=path)
make clean       # Remove container and all data (dangerous!)
```

## Deployment to EC2

1. Copy files to EC2:
   ```bash
   scp -r .env docker-compose.yml Makefile ubuntu@your-ec2-ip:~/rustfs/
   ```

2. SSH to EC2 and start:
   ```bash
   ssh ubuntu@your-ec2-ip
   cd rustfs
   make up
   ```

3. Update security group to allow:
   - Port 9000 (API)
   - Port 9001 (Web Console)

## Backup & Restore

```bash
# Create backup
make backup

# Restore from backup
make restore BACKUP_FILE=rustfs-backup-20260115_120000.tar.gz
```

## Troubleshooting

**Buckets disappear after restart?**
- Fixed! The volume is now correctly mounted to `/data` instead of `/data/rustfs`

**Permission denied errors?**
- RustFS runs as UID 10001. The Makefile automatically sets ownership.

**Container won't start?**
- Check logs: `make logs`
- Verify ports aren't in use: `netstat -tulpn | grep -E '9000|9001'`
