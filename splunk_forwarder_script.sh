#!/bin/bash

# Install utils tool
sudo yum install wget

cd /opt
# Download the Splunk Universal Forwarder package
sudo wget -O splunkforwarder-9.0.4-de405f4a7979-Linux-x86_64.tgz "https://download.splunk.com/products/universalforwarder/releases/9.0.4/linux/splunkforwarder-9.0.4-de405f4a7979-Linux-x86_64.tgz"

# Extract the package
sudo tar -xvzf splunkforwarder-9.0.4-de405f4a7979-Linux-x86_64.tgz -C /opt

cd /splunkforwarder/bin/
sudo ./splunk disable boot-start

sudo groupadd splunk #create the group splunk
sudo useradd -m -d /home/splunk splunk -g splunk #create the user splunk and bing it to the group splunk
sudo chown -R splunk:splunk /opt/splunkforwarder
sudo ./splunk enable boot-start -systemd-managed 1 -user splunk -group splunk