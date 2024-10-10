#!/bin/bash

#-----------------------------------------------------------------------------------------------------------------------#
# Date : 27 SEP 2024                                                                                                    #
# Description : We're writing this script to install a JFROG server from a Docker image on an amazon linux 2 machine.   #
# Write By : Hermann90 for Utrains                                                                                      #                                                                                             #
#-----------------------------------------------------------------------------------------------------------------------#

# Global Variable Declaration
# Global Variable Declaration
declare JFROG_NAME="artifactory-oss"
declare JFROG_FAMILY_NAME="jfrog-artifactory-oss"
declare JFROG_VERSION="6.9.6"
declare JFROG_DIR_NAME="artifactory"
declare JFROG_HOME=/opt/$FROG_DIR_NAME
declare JFROG_USER="artifactory"

#-----------------------------------------------------------------------------------------------------------------------#
# Step 0 : Functions Declaration                                                                                        #
# Description : This section is dedicated to the Declaration of functions that will be used later in our scripts.       #
#-----------------------------------------------------------------------------------------------------------------------#
# This function takes a step as parameter (exampe etap 1), then the service name (example docker), 
# then confirms whether or not the service has been installed.
confirm_installation_step () {
	if [ $? -eq 0 ]; then
		echo ">>>>>>>>>>>>>>>> $1 : $2 SUCESS <<<<<<<<<<<<<<<<"
		echo "$2 is installed Successfully"
		echo ">>>>>>>>>>>>>>>> Thanks to configure $2 <<<<<<<<<<<<<<<<"
	else
		echo "**************** $1 : Service $2 Failled ****************"
		echo " Sorry, we can't continue with this installation. Please check why the $2 service has not been installed."
		exit 1
	fi
} 

# Step 1 : Install Java 17, and config JAVA_HOME environment variable
echo "---------------- STEP 1 : JAVA INSTALLATION ----------------"
#wget https://download.oracle.com/java/17/latest/jdk-17_linux-aarch64_bin.tar.gz
#sudo tar -xzvf jdk-17_linux-aarch64_bin.tar.gz -C /opt
sudo yum install java-17* -y

JAVA_PATH=`find /usr/lib/jvm/java-11* | head -n 3 | grep 64`
export JAVA_HOME=$JAVA_PATH
export PATH=${JAVA_HOME}:${PATH}



### Configure the path variable 
cat > /tmp/java_path.sh << EOF
# Confifuration file for java path
export JAVA_HOME=$JAVA_PATH
export PATH=${JAVA_HOME}:${PATH}
EOF

sudo cp /tmp/java_path.sh /etc/profile.d/
sudo chmod +x /etc/profile.d/java_path.sh
source /etc/profile.d/java_path.sh

echo $JAVA_HOME | grep java





# Confirm whether step 1 has been successfully completed before proceeding.
confirm_installation_step "STEP 1" "JAVA"

# Step 2 : Get Jfrog zip file
# ---> Download Artifactory from jfrog.bintray.com
# ---> Create Data Directory on host system (The JFROG_DIR)
# ---> unzip the file downloaded in the JFROG_HOME
# The Jfrog zip file is located in : https://jfrog.bintray.com/artifactory/jfrog-artifactory-oss-6.9.6.zip
echo "---------------- STEP 2 : GET FROG ZIP FILE FOR INSTALLATION ----------------"
sudo wget https://jfrog.bintray.com/artifactory/$JFROG_FAMILY_NAME-$JFROG_VERSION.zip
sudo mkdir $JFROG_HOME
sudo unzip -q $JFROG_FAMILY_NAME-$JFROG_VERSION.zip -d $JFROG_HOME
ls $JFROG_HOME/$JFROG_NAME-$JFROG_VERSION/ | grep bin

# Confirm whether step 2 has been successfully completed before proceeding.
confirm_installation_step "STEP 2" "GET JFROG AND UNZIP"
sudo chown -R artifactory: $JFROG_HOME/*

# STEP 3 : create artifactory user and his home directory
echo "---------------- STEP 3 : ADD JFROG USER----------------"
sudo useradd -r -m -U -d $JFROG_HOME -s /bin/false $JFROG_USER
#confirm_installation_step "STEP 3" "ADD JFROG USER"

# STEP 4 : Configure JFrog as linux service
# ---> create artifactory.service file
echo "---------------- STEP 4 : CONFIG JFROG AS SERVICE----------------"
cat <<EOF | sudo tee artifactory.service
[Unit]
Description=JFROG Artifactory
After=syslog.target network.target

[Service]
Type=forking

Environment="JAVA_HOME=$JAVA_HOME"
Environment="CATALINA_PID=/opt/artifactory/artifactory-oss-6.9.6/run/artifactory.pid"
Environment="CATALINA_HOME=/opt/artifactory/artifactory-oss-6.9.6/tomcat"
Environment="CATALINA_BASE=/opt/artifactory/artifactory-oss-6.9.6/tomcat"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

ExecStart=/opt/artifactory/artifactory-oss-6.9.6/bin/artifactory.sh start
ExecStop=/opt/artifactory/artifactory-oss-6.9.6/bin/artifactory.sh stop

User=artifactory
Group=artifactory
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo mv artifactory.service /etc/systemd/system/artifactory.service

# validate the jfrog service configuration
confirm_installation_step "STEP 4" "CONFIG JFROG AS SERVICE"

# STEP 5 : Start Jfrog, enable it and check if the Jfrog service is up and ruinning 
echo "---------------- STEP 5 : STARTING JFROG ... ----------------"
echo "*****Starting Artifactory Service"
sudo systemctl start artifactory 
sudo systemctl enable artifactory

#Check whether Artifactory Service is running
systemctl status artifactory | grep "running"
# Confirm whether Step 4 has been successfully completed before proceeding.
confirm_installation_step "Step 4" "artifactory"

# End ok the installation
echo ">>>>>>>>>>>>>>>> SUCESS JFROG INSTALLATION <<<<<<<<<<<<<<<<"
echo "End of JFROG installation in a docker image"