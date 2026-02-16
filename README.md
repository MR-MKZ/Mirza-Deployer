# 🚀 Mirza Deployer

**Mirza Deployer** is a robust, all-in-one Dockerized solution designed to easily deploy and manage [MirzaBot]().

This repository automates the entire stack setup—including **Nginx** (web server), **MySQL** (database), **PHP-FPM** (application), and **phpMyAdmin**—while handling **SSL certificate generation** and **bot installation** automatically.

---

## ✨ Features

* **🐳 Fully Dockerized**: Runs in isolated containers for maximum stability and security.
* **🔒 Automatic SSL**: Built-in script to generate free Let's Encrypt SSL certificates.
* **🤖 Auto-Installer**: Automatically fetches the latest version of MirzaBot from GitHub and configures it.
* **⚙️ Zero-Config Nginx**: Generates a production-ready Nginx configuration file tailored to your domain.
* **🔄 Supervisor & Cron**: Built-in process management and cron jobs to keep your bot running smoothly.
* **🗄️ Database Management**: Includes **phpMyAdmin** for easy database access via a web interface.

---

## 🛠️ Prerequisites

Before you begin, ensure you have the following installed on your server (VPS):

* **Docker** & **Docker Compose**
* **Git**
* A valid **Domain Name** pointed to your server's IP address.

---

## 🚀 Installation Guide

Follow these simple steps to get your bot up and running in minutes.

### 1. Clone the Repository

```bash
git clone https://github.com/Mr-MKZ/Mirza-Deployer.git
cd Mirza-Deployer

```

### 2. Configure Environment

Copy the example environment file and edit it with your details.

```bash
cp .env.example .env
nano .env

```

> **Note:** Make sure to set your `DOMAIN`, `BOT_TOKEN`, and `ADMIN_ID` in the `.env` file.

### 3. Run the Setup Script

This script checks dependencies, generates your SSL certificate, and creates the Nginx configuration.

```bash
sudo chmod +x setup.sh
sudo ./setup.sh

```

* The script will ask for your domain if it's not set in `.env`.
* It will automatically request a certificate via Certbot.

### 4. Start the Containers

Once the setup is complete, launch the application.

```bash
docker compose up -d --build --remove-orphans

```

---

## 📂 Configuration Options

You can customize the deployment by modifying the `.env` file.

| Variable | Description | Default |
| --- | --- | --- |
| `BOT_HOST` | Hostname for the PHP container | `app` |
| `DB_NAME` | MySQL Database Name | `mirzaprobot` |
| `DB_USER` | MySQL User | `mirzauser` |
| `DB_PASS` | MySQL Password | `secure_password_here` |
| `BOT_TOKEN` | Your Telegram Bot Token | `123456:ABC...` |
| `ADMIN_ID` | Telegram User ID of the Admin | `123456789` |
| `DOMAIN` | Your domain (without https://) | `bot.yourdomain.com` |
| `BOT_VERSION` | Version of MirzaBot to install | `latest` |

---

## 🏗️ Architecture

This deployer sets up the following services:

1. **App (`mirzabot_app`)**: PHP 8.2-FPM container with all required extensions (gd, mysqli, zip, etc.).
2. **Web (`mirzabot_web`)**: Nginx Alpine container acting as a reverse proxy and SSL terminator.
3. **Database (`mirzabot_db`)**: MySQL 8.0 for storing bot data.
4. **PMA (`mirzabot_pma`)**: phpMyAdmin instance available at `https://yourdomain.com/phpmyadmin/`.

> But also you can change the container names (Don't forget to register their new names in .env file).

---

## 📝 Usage Notes

* **Webhooks**: The entrypoint script automatically sets your Telegram webhook to `https://yourdomain.com/index.php`.
* **Updates**: To update the bot version, change `BOT_VERSION` in your `.env` file and restart the container:
```bash
docker compose down
docker compose up -d

```


* **Database Config**: The `config.php` file is automatically generated. **Do not** edit it manually inside the container; it will be overwritten if missing.

---

## 👨‍💻 Credits

* **Deployer Script**: Developed by **Mr.MKZ**.
* **MirzaBot**: The original bot source code by [MahdiMGF2]().