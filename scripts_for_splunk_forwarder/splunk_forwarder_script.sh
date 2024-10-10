#!/bin/bash

# Global variable declaration
SPLUNK_FORWARD_PASS=abcd1234
SPLUNK_GROUP=splunk
SPLUNK_USER=splunk 

# Install utils tool
sudo yum install wget

cd /opt
# Download the Splunk Universal Forwarder package
sudo wget -O splunkforwarder-9.0.4-de405f4a7979-Linux-x86_64.tgz "https://download.splunk.com/products/universalforwarder/releases/9.0.4/linux/splunkforwarder-9.0.4-de405f4a7979-Linux-x86_64.tgz"

# Extract the package
sudo tar -xvzf splunkforwarder-9.0.4-de405f4a7979-Linux-x86_64.tgz -C /opt

cd /opt/splunkforwarder/bin/
sudo ./splunk disable boot-start

sudo groupadd ${SPLUNK_GROUP} #create the group splunk
sudo useradd -m -d /home/splunk ${SPLUNK_USER} -g ${SPLUNK_GROUP} #create the user splunk and bing it to the group splunk
sudo chown -R ${SPLUNK_USER}:${SPLUNK_GROUP} /opt/splunkforwarder
cd /opt/splunkforwarder/bin/
sudo ./splunk enable boot-start --accept-license --answer-yes --no-prompt --seed-passwd ${SPLUNK_FORWARD_PASS} -systemd-managed 1 -user ${SPLUNK_USER} -group ${SPLUNK_GROUP}

echo ">>>>>>>>>>>>>> SPLUNK FORWARDER INSTALLED SUCCESSFULLY <<<<<<<<<<<<<<<"