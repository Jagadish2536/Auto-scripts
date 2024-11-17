#!/bin/bash

# Define color codes for output
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"  # Reset color

# Define log file with timestamp
TIME=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$(basename $0)-$TIME.log"

# Check if the script is run as root
ID=$(id -u)

if [ $ID -ne 0 ]; then
    echo "You are not root user"
    exit 1
else
    echo "You are a root user"
fi  

# Function to validate the exit status of commands
VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "${R}$2 failed${N}"
        exit 1
    else
        echo -e "${G}$2 succeeded${N}"
    fi
}

# Install nginx
dnf install nginx -y &>> $LOGFILE
VALIDATE $? "Install nginx"

# Enable nginx service
systemctl enable nginx &>> $LOGFILE
VALIDATE $? "Enable nginx"

# Start nginx service
systemctl start nginx &>> $LOGFILE
VALIDATE $? "Start nginx"

# Remove old data
rm -rf /usr/share/nginx/html/* &>> $LOGFILE
VALIDATE $? "Remove old data"

# Download the web.zip file
curl -o /tmp/web.zip https://roboshop-builds.s3.amazonaws.com/web.zip &>> $LOGFILE
VALIDATE $? "Download data"

# Unzip the downloaded web.zip file
cd /usr/share/nginx/html
unzip -o /tmp/web.zip &>> $LOGFILE
VALIDATE $? "Unzip data"

# Copy the new roboshop.conf file
cp roboshop.conf /etc/nginx/default.d/roboshop.conf &>> $LOGFILE
VALIDATE $? "Copy new data"

# Restart nginx service
systemctl restart nginx &>> $LOGFILE
VALIDATE $? "Restart nginx"
