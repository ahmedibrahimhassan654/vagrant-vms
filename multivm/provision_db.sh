#!/bin/bash

set -e

echo "Updating system packages..."
echo "Configuring CentOS vault repos (EOL fix)..."
sed -i 's/mirror.centos.org/vault.centos.org/g' /etc/yum.repos.d/CentOS-Base.repo
sed -i 's/^mirrorlist/#mirrorlist/' /etc/yum.repos.d/CentOS-Base.repo
sed -i 's/^#baseurl/baseurl/' /etc/yum.repos.d/CentOS-Base.repo

yum update -y


yum clean all

echo "Installing MariaDB..."
yum install -y mariadb-server mariadb

echo "Configuring MariaDB for remote access..."
grep -q '^bind-address' /etc/my.cnf && \
  sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/my.cnf || \
  sed -i '/^\[mysqld\]/a bind-address = 0.0.0.0' /etc/my.cnf

echo "Starting and enabling MariaDB..."
systemctl enable mariadb
systemctl start mariadb

echo "Configuring MariaDB..."
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS appdb;
USE mysql;
DELETE FROM user WHERE user='appuser' AND host='%';
FLUSH PRIVILEGES;
CREATE USER 'appuser'@'%' IDENTIFIED BY 'vagrant';
GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'%';
FLUSH PRIVILEGES;
EOF

echo "Opening MariaDB port in firewall..."
firewall-cmd --permanent --add-service=mysql 2>/dev/null || true
firewall-cmd --reload 2>/dev/null || true

echo "Provisioning complete!"
