#!/bin/bash

set -e

echo "Updating system packages..."
apt-get update && apt-get upgrade -y

echo "Installing Apache..."
apt-get install -y apache2 wget unzip

echo "Downloading tooplate template..."
TEMPLATE_URL="https://www.tooplate.com/download/2121_wave_cafe"
TEMPLATE_DIR="2121_wave_cafe"

rm -rf /var/www/html/*
wget -q "$TEMPLATE_URL" -O /tmp/template.zip
unzip -q /tmp/template.zip -d /tmp/
cp -r "/tmp/$TEMPLATE_DIR/"* /var/www/html/
rm -rf /tmp/template.zip "/tmp/$TEMPLATE_DIR"

echo "Setting permissions..."
chown -R www-data:www-data /var/www/html

echo "Starting Apache..."
systemctl enable apache2
systemctl start apache2

echo "Provisioning complete!"
