FROM mysql:8.0 AS mysql-client

FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    dirmngr \
    ca-certificates \
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
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libncurses6 \
    libtinfo6 \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=mysql-client /usr/bin/mysql /usr/bin/mysql
COPY --from=mysql-client /usr/bin/mysqldump /usr/bin/mysqldump

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN install-php-extensions \
    gd \
    mysqli \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    zip \
    intl \
    soap \
    ssh2

RUN echo "max_execution_time = 300" > /usr/local/etc/php/conf.d/timeout.ini \
    && echo "memory_limit = 256M" > /usr/local/etc/php/conf.d/memory.ini

RUN mkdir -p /var/log/supervisor
COPY ./configs/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN echo "* * * * * cd /var/www/html && /usr/local/bin/php cronbot/cron.php >> /var/log/cron.log 2>&1" > /etc/cron.d/mirzabot-cron
RUN chmod 0644 /etc/cron.d/mirzabot-cron
RUN crontab /etc/cron.d/mirzabot-cron
RUN touch /var/log/cron.log

WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html

CMD ["/usr/bin/supervisord"]
