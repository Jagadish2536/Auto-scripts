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

# Install Remi repository
dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm -y &>> $LOGFILE
VALIDATE $? "Downloading Remi repository"

# Enable Redis 6.2 module
dnf module enable redis:remi-6.2 -y &>> $LOGFILE
VALIDATE $? "Enabling Redis module"

# Install Redis
dnf install redis -y &>> $LOGFILE
VALIDATE $? "Installing Redis"

# Update Redis configuration to allow external connections
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis.conf &>> $LOGFILE
VALIDATE $? "Updating /etc/redis.conf for external connections"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf &>> $LOGFILE
VALIDATE $? "Updating /etc/redis/redis.conf for external connections"

# Enable Redis service to start on boot
systemctl enable redis &>> $LOGFILE
VALIDATE $? "Enabling Redis service"

# Start Redis service
systemctl start redis &>> $LOGFILE
VALIDATE $? "Starting Redis service"
