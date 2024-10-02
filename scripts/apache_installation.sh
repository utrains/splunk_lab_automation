#!/bin/bash

# Update package lists
sudo yum update -y

# Install Apache
sudo yum install httpd -y

# Start Apache service
sudo systemctl start httpd

# Enable Apache to start on boot
sudo systemctl enable httpd

# Display Apache status
sudo systemctl status httpd