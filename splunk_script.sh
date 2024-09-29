#!/bin/bash

SPLUNK_USER="admin"
SPLUNK_PASSWORD="abcd1234"

# Install utils tool
sudo yum install wget
cd /opt

# Download the Splunk Enterprise tar file
sudo wget -O splunk-9.0.4.1-419ad9369127-Linux-x86_64.tgz "https://download.splunk.com/products/splunk/releases/9.0.4.1/linux/splunk-9.0.4.1-419ad9369127-Linux-x86_64.tgz"

# Extract the tar file to /opt
sudo tar -zxvf splunk-9.0.4.1-419ad9369127-Linux-x86_64.tgz -C /opt

cd splunk/bin/
sudo ./splunk start --accept-license --answer-yes --no-prompt --seed-passwd $SPLUNK_PASSWORD
sudo ./splunk enable listen 9997 -auth $SPLUNK_USER:$SPLUNK_PASSWORD
sudo ./splunk enable boot-start
