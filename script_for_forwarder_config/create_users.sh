#!/bin/bash


#-----------------------------------------------------------------------------------------------------------------------#
# Date : 27 SEP 2024                                                                                                    #
# Description : This script creates users and enables them to connect remotely to the splunk server.                    #
#               You have a file containing the passwords of the created users                                           #
# Write By : Hermann90 for Utrains                                                                                      #                                                                                             
#-----------------------------------------------------------------------------------------------------------------------#


# Ensuring root privileges : Check if the current user is a superuser, exit if the user is not
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Check if the file was passed into the script
if [ -z "$1" ]; then 
    echo "Please pass the file parameter"
    exit 1
fi

# Define the file paths for the log file, and the password file
INPUT_FILE="$1"
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Generate logfiles and password files and grant the user the permissions to edit the password file
touch $LOG_FILE
mkdir -p /var/secure
chmod 700 /var/secure
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Generate logs and passwords 
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

generate_password() {
    openssl rand -base64 12
}

# Read the input file line by line and save them into variables
while IFS=';' read -r username groups || [ -n "$username" ]; do
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)
    # Check if the personal group exists, create one if it doesn't
    if ! getent group "$username" &>/dev/null; then
        echo "Group $username does not exist, adding it now"
        groupadd "$username"
        log_message "Created personal group $username"
    fi

    # Check if the user exists
    if id -u "$username" &>/dev/null; then
        echo "User $username exists"
        log_message "User $username already exists"
    else

        # Create a new user with the created group if the user does not exist
        useradd -m -g $username -s /bin/bash "$username"
        log_message "Created a new user $username"
    fi

    # Check if the groups were specified
    if [ -n "$groups" ]; then
        # Read through the groups saved in the groups variable created earlier and split each group by ','
        IFS=',' read -r -a group_array <<< "$groups"
        # Loop through the groups 
        for group in "${group_array[@]}"; do

            # Remove the trailing and leading whitespaces and save each group to the group variable
            group=$(echo "$group" | xargs) # Remove leading/trailing whitespace
            # Check if the group already exists
            if ! getent group "$group" &>/dev/null; then
                # If the group does not exist, create a new group
                groupadd "$group"
                log_message "Created group $group."
            fi

            # Add the user to each group
            usermod -aG "$group" "$username"
            log_message "Added user $username to group $group."
        done
    fi

    # Create and set a user password
    password=$(generate_password)
    echo "$username:$password" | chpasswd
    # Save user and password to a file
    echo "$username,$password" >> $PASSWORD_FILE
done < "$INPUT_FILE"


# 
sudo sed -re 's/^(PasswordAuthentication)([[:space:]]+)no/\1\2yes/' -i.`date -I` /etc/ssh/sshd_config
sudo systemctl restart sshd
log_message "User created successfully"

echo "Users have been created and added to their groups successfully"


