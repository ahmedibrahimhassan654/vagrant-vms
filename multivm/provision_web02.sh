#!/bin/bash

set -e

DB_NAME="appdb"
DB_USER="appuser"
DB_PASSWORD="vagrant"
DB_HOST="192.168.56.12"

echo "Updating system packages..."
apt-get update && apt-get upgrade -y

echo "Installing Apache, PHP and extensions..."
apt-get install -y \
    apache2 \
    php \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-xmlrpc \
    php-soap \
    php-intl \
    php-zip \
    libapache2-mod-php \
    wget \
    unzip

echo "Downloading WordPress..."
wget -q https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
tar -xzf /tmp/wordpress.tar.gz -C /tmp/
rm -rf /var/www/html/*
cp -r /tmp/wordpress/* /var/www/html/
rm -rf /tmp/wordpress.tar.gz /tmp/wordpress

echo "Configuring wp-config.php..."
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i "s/database_name_here/${DB_NAME}/" /var/www/html/wp-config.php
sed -i "s/username_here/${DB_USER}/" /var/www/html/wp-config.php
sed -i "s/password_here/${DB_PASSWORD}/" /var/www/html/wp-config.php
sed -i "s/localhost/${DB_HOST}/" /var/www/html/wp-config.php

echo "Setting permissions..."
chown -R www-data:www-data /var/www/html

echo "Restarting Apache..."
systemctl enable apache2
systemctl restart apache2

echo "Provisioning complete!"
