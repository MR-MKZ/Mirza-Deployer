FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libssh2-1-dev \
    libicu-dev \
    cron \
    supervisor \
    default-mysql-client \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install mysqli pdo_mysql mbstring exif pcntl bcmath gd zip intl soap

RUN pecl install ssh2-1.3.1 \
    && docker-php-ext-enable ssh2

RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN echo "* * * * * cd /var/www/html && /usr/local/bin/php cronbot/cron.php >> /var/log/cron.log 2>&1" > /etc/cron.d/mirzabot-cron
RUN chmod 0644 /etc/cron.d/mirzabot-cron
RUN crontab /etc/cron.d/mirzabot-cron
RUN touch /var/log/cron.log

WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html

CMD ["/usr/bin/supervisord"]
