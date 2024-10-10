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

echo "<html><h1>Welcome!!! this is a Apache Web Server on EC2 Deployed by Kathya :)</h1></html>" | sudo tee /var/www/html/index.html

echo "InvalidDirective here" | sudo tee /var/www/html/.htaccess

sudo sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

sudo systemctl restart httpd

# NB : The log file of httpd is /var/log/httpd/access_log 