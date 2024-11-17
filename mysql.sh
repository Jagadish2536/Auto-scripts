#!/bin/bash

R="\e[31m"  # Red color for error
G="\e[32m"  # Green color for success
Y="\e[33m"  # Yellow color (not used here)
N="\e[0m"   # Reset color

TIME=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIME.log"

ID=$(id -u)

if [ $ID -ne 0 ]; then
    echo "You are not root user"
    exit 1
else
    echo "You are a root user"
fi

# Function to validate commands and print appropriate messages
VALIDATE() {
    if [ $? -ne 0 ]; then  # Check exit status of last command
        echo -e "${R}$2 failed${N}"  # Print failure in red
        exit 1
    else
        echo -e "${G}$2 success${N}"  # Print success in green
    fi
}

# Disable the mysql module if already enabled
dnf module disable mysql -y &>> $LOGFILE
VALIDATE "disable mysql"

# Copy the MySQL repo file
cp mysql.repo /etc/yum.repos.d/mysql.repo &>> $LOGFILE
VALIDATE "creating mysql.repo"

# Install the MySQL community server
dnf install mysql-community-server -y &>> $LOGFILE
VALIDATE "installing mysql"

# Enable the MySQL service to start on boot
systemctl enable mysqld &>> $LOGFILE
VALIDATE "enabling mysql"

# Start the MySQL service
systemctl start mysqld &>> $LOGFILE
VALIDATE "starting mysql"

# Secure the MySQL installation with a root password
mysql_secure_installation --set-root-pass RoboShop@1 &>> $LOGFILE
VALIDATE "password changed for mysql"

# Test if the MySQL root password works
mysql -uroot -pRoboShop@1 -e "SELECT 1;" &>> $LOGFILE
VALIDATE "password is working or not"
