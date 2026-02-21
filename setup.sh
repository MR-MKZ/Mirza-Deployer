#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' 

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Error: Please run this script as root (sudo ./setup.sh).${NC}"
    exit 1
fi

echo -e "${GREEN}🚀 Starting Environment Setup...${NC}"

if [ -f "$ENV_FILE" ]; then
    export "$(grep -v '^#' "$ENV_FILE" | xargs)"
    DOMAIN_VAR=$DOMAIN
fi

echo -e "${YELLOW}🔍 Checking dependencies...${NC}"
DEPENDENCIES=(docker curl sed)
for cmd in "${DEPENDENCIES[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}❌ Error: $cmd is not installed.${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✅ Dependencies met.${NC}"

ENV_FILE=".env"
DOMAIN_VAR=""

if [ -f "$ENV_FILE" ]; then
    DOMAIN_VAR=$(grep "^DOMAIN=" "$ENV_FILE" | cut -d '=' -f2-)
fi

if [ -z "$DOMAIN_VAR" ]; then
    echo -e "${YELLOW}⚠️  Domain not found in .env file.${NC}"
    read -r -p "👉 Enter your domain (e.g., bot.example.com): " USER_INPUT
    
    if [ -z "$USER_INPUT" ]; then
        echo -e "${RED}❌ Error: Domain cannot be empty.${NC}"
        exit 1
    fi
    
    DOMAIN_VAR=$USER_INPUT
    
    if [ ! -f "$ENV_FILE" ]; then
        echo "DOMAIN=$DOMAIN_VAR" > "$ENV_FILE"
        echo -e "${GREEN}✅ Created .env file with DOMAIN=$DOMAIN_VAR${NC}"
    else
        echo "" >> "$ENV_FILE"
        echo "DOMAIN=$DOMAIN_VAR" >> "$ENV_FILE"
        echo -e "${GREEN}✅ Added DOMAIN to existing .env${NC}"
    fi
fi

CLEAN_DOMAIN="${DOMAIN_VAR#*://}"
CLEAN_DOMAIN="${CLEAN_DOMAIN%/}"

echo -e "${GREEN}🎯 Target Domain: $CLEAN_DOMAIN${NC}"

SSL_SCRIPT="./scripts/gen-ssl.sh"

if [ ! -f "$SSL_SCRIPT" ]; then
    echo -e "${RED}❌ Error: $SSL_SCRIPT not found in current directory.${NC}"
    exit 1
fi

echo -e "${YELLOW}🔐 Running SSL generation script...${NC}"
chmod +x "$SSL_SCRIPT"
./"$SSL_SCRIPT" "$CLEAN_DOMAIN"
SSL_EXIT_CODE=$?

if [ $SSL_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}❌ SSL Generation failed. Aborting setup.${NC}"
    exit 1
fi

NGINX_CONF_DIR="./configs"
NGINX_CONF_FILE="$NGINX_CONF_DIR/nginx.conf"

echo -e "${YELLOW}⚙️  Generating Nginx configuration...${NC}"

mkdir -p "$NGINX_CONF_DIR"

cat > "$NGINX_CONF_FILE" <<EOF
server {
    listen 80;
    server_name $CLEAN_DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $CLEAN_DOMAIN;

    # SSL Config
    ssl_certificate /etc/nginx/ssl/$CLEAN_DOMAIN.crt;
    ssl_certificate_key /etc/nginx/ssl/$CLEAN_DOMAIN.key;

    # Root & Index
    root /var/www/html/mirzaprobotconfig;
    index index.php index.html;

    # Logs
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass ${BOT_HOST:-app}:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }

    location ^~ /phpmyadmin/ {
        proxy_pass http://${PMA_HOST:-pma}:80/;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }
}
EOF

echo -e "${GREEN}✅ Nginx configuration saved to: $NGINX_CONF_FILE${NC}"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   SETUP COMPLETE                     ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo -e "${MAGENTA}Script by Mr.MKZ${NC}"
echo ""
echo -e "1. Ensure your ${YELLOW}docker-compose.yml${NC} nginx maps the volumes correctly:"
echo -e "   - ${YELLOW}./ssl:/etc/nginx/ssl:ro${NC}"
echo -e "   - ${YELLOW}./configs/nginx.conf:/etc/nginx/conf.d/default.conf${NC}"
echo ""
echo -e "2. Start your containers:"
echo -e "   ${YELLOW}docker compose up -d --build --remove-orphans${NC}"
echo ""