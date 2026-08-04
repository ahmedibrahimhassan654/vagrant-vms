#!/bin/bash

# Variable Declaration
PACKAGE="httpd wget unzip"
SVC="httpd"
#URL='https://www.tooplate.com/zip-templates/2098_health.zip'
#ART_NAME='2098_health'
TEMPDIR="/tmp/webfiles"
website_folder="/var/www/html/"

# Installing Dependencies
echo "########################################"
echo "Installing packages."
echo "########################################"
sudo yum install $PACKAGE -y > /dev/null
echo

# Start & Enable Service
echo "########################################"
echo "Start & Enable HTTPD Service"
echo "########################################"
sudo systemctl start $SVC
sudo systemctl enable $SVC
echo

# Creating Temp Directory
echo "########################################"
echo "Starting Artifact Deployment"
echo "########################################"
mkdir -p $TEMPDIR
cd $TEMPDIR
echo

wget $1 > /dev/null
unzip $2.zip > /dev/null
sudo cp -r $2/* $website_folder
echo

# Bounce Service
echo "########################################"
echo "Restarting HTTPD service"
echo "########################################"
systemctl restart $SVC 
echo

# Clean Up
echo "########################################"
echo "Removing Temporary Files"
echo "########################################"
rm -rf $TEMPDIR
echo

sudo systemctl status $SVC --no-pager

# listing /var/www/html/
echo "########################################"
echo "listing /var/www/html/"
echo "########################################"

ls $website_folder


# Display Website URL
echo "########################################"
echo "Website URL"
echo "########################################"

VM_IP=$(ip -4 -o addr show | awk '$4 ~ /^192\.168\.10\./ {sub("/.*", "", $4); print $4; exit}')

echo "Open the website in your browser:"
echo "http://${VM_IP}"
