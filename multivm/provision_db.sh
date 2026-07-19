#!/bin/bash

set -e

echo "Updating system packages..."
yum update -y

echo "Installing MariaDB..."
yum install -y epel-release
yum install -y mariadb-server mariadb

echo "Configuring MariaDB for remote access..."
sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/my.cnf
sed -i 's/^#bind-address.*/bind-address = 0.0.0.0/' /etc/my.cnf

echo "Starting and enabling MariaDB..."
systemctl enable mariadb
systemctl start mariadb

echo "Configuring MariaDB..."
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS appdb;
CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY 'vagrant';
GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'%';
FLUSH PRIVILEGES;
EOF

echo "Opening MariaDB port in firewall..."
firewall-cmd --permanent --add-service=mysql
firewall-cmd --reload

echo "Provisioning complete!"
