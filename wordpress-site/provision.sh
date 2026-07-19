#!/bin/bash

set -e

DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASSWORD="vagrant"

echo "Updating system packages..."
apt-get update && apt-get upgrade -y

echo "Installing Apache, MySQL, PHP and extensions..."
apt-get install -y \
    apache2 \
    mysql-server \
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

echo "Configuring MySQL for WordPress..."
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

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

echo "Setting permissions..."
chown -R www-data:www-data /var/www/html

echo "Restarting Apache..."
systemctl enable apache2
systemctl restart apache2

echo "Provisioning complete!"
echo "WordPress URL: http://192.168.56.79/"
