#!/bin/bash

#-----------------------------------------------------------------------------------------------------------------------#
# Date : 27 SEP 2024                                                                                                    #
# Description : This script file allows you to configure : host server server,  configure splunk server log directories #
# Write By : Hermann90 for Utrains                                                                                      #                                                                                             #
#-----------------------------------------------------------------------------------------------------------------------#

# Global variable declaration
PORT=9997
SPLUNK_USER=admin
SPLUNK_PASSWORD=abcd1234

echo "---------------- STEP 1 : CONFIG THE HOSTNAME FOR SPLUNK FORWADER ----------------"
cd /opt/splunkforwarder/bin
./splunk show servername
./splunk set servername jfrog
./splunk set default-hostname jfrog
sudo hostnamectl set-hostname jfrog

# Web server ERROR 500 checking and generation
echo "---------------- STEP 2 : HTTPD WEB SERVER ERROR 500 CHECK ----------------"
sudo cat /var/log/httpd/access_log | grep 500

# $1 is the ip address of the splunk server already created 
echo "---------------- STEP 3 : CONFIG LOGS TO SPLUNK FORWADER ----------------"
echo IP_SPLUNK_SERVER: "$1:$PORT"
cd /opt/splunkforwarder/bin/
sudo ./splunk add forward-server "$1:$PORT"

sudo ./splunk list forward-server

# add the folder for the server logs
sudo ./splunk add monitor /var/log

# Add the folder to monitor the Jfrog logs
sudo ./splunk add monitor /opt/artifactory/artifactory-oss-6.9.6/logs


sudo ./splunk restart --seed-passwd ${SPLUNK_PASSWORD} -user ${SPLUNK_USER}
sudo ./splunk list forward-server

echo ">>>>>>>>>>>>>> SPLUNK FORWARDER CONFIGURED SUCCESSFULLY <<<<<<<<<<<<<<<"