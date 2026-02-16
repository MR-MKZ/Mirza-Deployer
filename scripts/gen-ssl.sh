#!/bin/bash

# ==========================================
# SSL GENERATION SCRIPT FOR MIRZABOT
# ==========================================

if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Please run this script as root (use sudo)."
    exit 1
fi

DOMAIN_NAME=$1
if [ -z "$DOMAIN_NAME" ]; then
    DOMAIN_NAME=$DOMAIN
fi

if [ -z "$DOMAIN_NAME" ]; then
    echo -n "Enter the domain name (e.g., bot.example.com): "
    read -r DOMAIN_NAME
fi

if [ -z "$DOMAIN_NAME" ]; then
    echo "❌ Error: No domain provided. Exiting."
    exit 1
fi

if ! command -v certbot &> /dev/null; then
    echo "⚙️  Certbot not found. Installing..."
    apt-get update -y
    apt-get install -y certbot
    if [ ! "$(apt-get install -y certbot)" ]; then
        echo "❌ Error: Failed to install Certbot."
        exit 1
    fi
    echo "✅ Certbot installed successfully."
else
    echo "✅ Certbot is already installed."
fi

PROJECT_DIR=$(pwd)
SSL_OUTPUT_DIR="$PROJECT_DIR/ssl"
LETSENCRYPT_DIR="/etc/letsencrypt/live/$DOMAIN_NAME"

mkdir -p "$SSL_OUTPUT_DIR"

echo "=================================================="
echo "🔒 Target Domain:  $DOMAIN_NAME"
echo "📂 Project Path:   $PROJECT_DIR"
echo "📂 SSL Output:     $SSL_OUTPUT_DIR"
echo "=================================================="

SERVICE_STOPPED=""

if systemctl is-active --quiet nginx; then
    echo "🛑 Stopping Nginx to free up Port 80..."
    systemctl stop nginx
    SERVICE_STOPPED="nginx"
elif systemctl is-active --quiet apache2; then
    echo "🛑 Stopping Apache to free up Port 80..."
    systemctl stop apache2
    SERVICE_STOPPED="apache2"
fi

echo "🚀 Requesting Certificate from Let's Encrypt..."

# --non-interactive: Run without asking for input
# --agree-tos: Agree to Terms of Service
# --email: Register email (optional but recommended, using admin@domain)
# --standalone: Use built-in web server for auth
certbot certonly --standalone \
    --non-interactive \
    --agree-tos \
    --email "admin@$DOMAIN_NAME" \
    --preferred-challenges http \
    -d "$DOMAIN_NAME"

CERTBOT_EXIT_CODE=$?

if [ -n "$SERVICE_STOPPED" ]; then
    echo "▶️  Restarting $SERVICE_STOPPED..."
    systemctl start "$SERVICE_STOPPED"
fi

if [ $CERTBOT_EXIT_CODE -eq 0 ] && [ -d "$LETSENCRYPT_DIR" ]; then
    echo "📋 Copying certificates to local folder..."

    # Use -L to follow symlinks and copy actual file content
    cp -L "$LETSENCRYPT_DIR/fullchain.pem" "$SSL_OUTPUT_DIR/$DOMAIN_NAME.crt"
    cp -L "$LETSENCRYPT_DIR/privkey.pem" "$SSL_OUTPUT_DIR/$DOMAIN_NAME.key"

    # Set permissions: Readable by owner (root), readable by group/others
    chmod 644 "$SSL_OUTPUT_DIR/$DOMAIN_NAME.crt"
    chmod 644 "$SSL_OUTPUT_DIR/$DOMAIN_NAME.key"

    echo ""
    echo "✅ SUCCESS! SSL Certificates generated."
    echo "   - Certificate: $SSL_OUTPUT_DIR/$DOMAIN_NAME.crt"
    echo "   - Private Key: $SSL_OUTPUT_DIR/$DOMAIN_NAME.key"
    echo ""
    echo "👉 You can now mount './ssl' into your Docker container."
else
    echo ""
    echo "❌ FAILED. Certificate generation failed."
    echo "   Check the logs above for details."
    exit 1
fi