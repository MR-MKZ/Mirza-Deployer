#!/bin/bash

# Configuration
REPO_OWNER="mahdiMGF2"
REPO_NAME="mirzabot"
INSTALL_DIR="/var/www/html"

# 1. Download Code if directory is empty
if [ -z "$(ls -A $INSTALL_DIR)" ]; then
    echo "Directory empty. Fetching $BOT_VERSION from GitHub..."

    if [ "$BOT_VERSION" == "latest" ]; then
        # Fetch the latest release tag URL using GitHub API
        DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest" | jq -r '.zipball_url')
    else
        # Use specific tag
        DOWNLOAD_URL="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/tags/$BOT_VERSION.zip"
    fi

    echo "Downloading from: $DOWNLOAD_URL"
    
    # Download zip
    curl -L -o /tmp/bot.zip "$DOWNLOAD_URL"
    
    # Unzip
    unzip -q /tmp/bot.zip -d /tmp/
    
    # Move files (GitHub zips usually have a root folder like 'username-repo-hash')
    EXTRACTED_FOLDER=$(find /tmp -maxdepth 1 -type d -name "$REPO_OWNER-$REPO_NAME*")
    
    if [ -d "$EXTRACTED_FOLDER" ]; then
        mv "$EXTRACTED_FOLDER"/* "$INSTALL_DIR/"
        echo "Files extracted successfully."
    else
        echo "Error: Could not find extracted folder."
        ls -la /tmp
        exit 1
    fi
    
    # Cleanup
    rm -rf /tmp/bot.zip "$EXTRACTED_FOLDER"
    
    # Fix permissions
    chown -R www-data:www-data "$INSTALL_DIR"
fi

# 2. Config.php Generation (Same as before)
CONFIG_FILE="$INSTALL_DIR/mirzaprobotconfig/config.php"
mkdir -p "$INSTALL_DIR/mirzaprobotconfig"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Generating config.php..."
    cat <<EOF > $CONFIG_FILE
<?php
\$dbname = '$DB_NAME';
\$usernamedb = '$DB_USER';
\$passworddb = '$DB_PASS';
\$connect = mysqli_connect("db", \$usernamedb, \$passworddb, \$dbname);
if (\$connect->connect_error) { die("error" . \$connect->connect_error); }
mysqli_set_charset(\$connect, "utf8mb4");
\$options = [ PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC, PDO::ATTR_EMULATE_PREPARES => false, ];
\$dsn = "mysql:host=db;dbname=\$dbname;charset=utf8mb4";
try { \$pdo = new PDO(\$dsn, \$usernamedb, \$passworddb, \$options); } catch (\PDOException \$e) { error_log("Database connection failed: " . \$e->getMessage()); }
\$APIKEY = '$API_KEY';
\$adminnumber = '$ADMIN_ID';
\$domainhosts = '$DOMAIN_HOST';
\$usernamebot = '$BOT_USERNAME';
?>
EOF
    chown www-data:www-data $CONFIG_FILE

    # Run Database Setup
    echo "Waiting for Database..."
    sleep 10
    # Attempt to run table.php if it exists
    php "$INSTALL_DIR/table.php" || echo "Warning: table.php not found or failed."
fi

# 3. Start Supervisor
exec /usr/bin/supervisord