#!/bin/bash

# RustFS SSL Setup Script with Let's Encrypt (Dual Domain)
# This script helps you set up SSL certificates for both API and Console subdomains

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== RustFS Dual-Domain SSL Setup with Let's Encrypt ===${NC}\n"

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

# Check if domains are set
if [ "$CONSOLE_DOMAIN" = "rustfs.yourdomain.com" ] || [ -z "$CONSOLE_DOMAIN" ]; then
    echo -e "${RED}Error: Please set your actual domains in .env file${NC}"
    echo "Edit .env and change:"
    echo "  CONSOLE_DOMAIN=rustfs.yourdomain.com"
    echo "  API_DOMAIN=api-rustfs.yourdomain.com"
    exit 1
fi

echo -e "${YELLOW}Console Domain:${NC} $CONSOLE_DOMAIN"
echo -e "${YELLOW}API Domain:${NC} $API_DOMAIN"
echo ""
echo -e "${YELLOW}Email for Let's Encrypt notifications:${NC}"
read -p "Enter your email: " EMAIL

if [ -z "$EMAIL" ]; then
    echo -e "${RED}Error: Email is required${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 1:${NC} Installing certbot..."
sudo apt update
sudo apt install -y certbot

echo ""
echo -e "${YELLOW}Step 2:${NC} Creating certbot directory..."
mkdir -p certbot/www

echo ""
echo -e "${YELLOW}Step 3:${NC} Stopping nginx if running..."
docker compose stop nginx 2>/dev/null || true

echo ""
echo -e "${YELLOW}Step 4:${NC} Obtaining SSL certificate for Console domain ($CONSOLE_DOMAIN)..."
sudo certbot certonly \
    --standalone \
    --preferred-challenges http \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$CONSOLE_DOMAIN"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to obtain SSL certificate for $CONSOLE_DOMAIN${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 5:${NC} Obtaining SSL certificate for API domain ($API_DOMAIN)..."
sudo certbot certonly \
    --standalone \
    --preferred-challenges http \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$API_DOMAIN"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to obtain SSL certificate for $API_DOMAIN${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ SSL certificates obtained successfully!${NC}"
echo ""
echo -e "${YELLOW}Step 6:${NC} Updating nginx configuration..."

# Replace domains in nginx config
sed -i "s/rustfs\.yourdomain\.com/$CONSOLE_DOMAIN/g" nginx/conf.d/rustfs.conf
sed -i "s/api-rustfs\.yourdomain\.com/$API_DOMAIN/g" nginx/conf.d/rustfs.conf

echo ""
echo -e "${YELLOW}Step 7:${NC} Starting services..."
make up

echo ""
echo -e "${GREEN}=== Setup Complete! ===${NC}"
echo ""
echo -e "Your RustFS is now accessible at:"
echo ""
echo -e "  ${GREEN}Web Console:${NC} https://$CONSOLE_DOMAIN/"
echo -e "  ${GREEN}API Endpoint:${NC} https://$API_DOMAIN/"
echo ""
echo -e "Health checks:"
echo -e "  ${GREEN}Console:${NC} https://$CONSOLE_DOMAIN/health"
echo -e "  ${GREEN}API:${NC} https://$API_DOMAIN/health"
echo ""
echo -e "Default credentials: ${YELLOW}$RUSTFS_ROOT_USER / $RUSTFS_ROOT_PASSWORD${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} Certificates will auto-renew. To manually renew:"
echo -e "  sudo certbot renew"
echo ""
