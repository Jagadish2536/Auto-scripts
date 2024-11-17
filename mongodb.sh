#!/bin/bash

R="\e[31m"  # Red color for error
G="\e[32m"  # Green color for success
Y="\e[33m"  # Yellow color (not used here)
N="\e[0m"   # Reset color

TIME=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIME.log"

ID=$(id -u)

# Check if the user is root
if [ $ID -ne 0 ]; then
    echo "You are not root user"
    exit 1
else
    echo "You are a root user"
fi

# Function to validate command success
VALIDATE() {
    if [ $? -ne 0 ]; then  # Check exit status of last command
        echo -e "${R}$2 failed${N}"  # Print failure in red
        exit 1
    else
        echo -e "${G}$2 success${N}"  # Print success in green
    fi
}

# Copy the MongoDB repo file
cp mongodb.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE "creating mongo.repo"

# Install MongoDB
dnf install mongodb-org -y &>> $LOGFILE
VALIDATE "installing mongodb"

# Enable the MongoDB service to start on boot
systemctl enable mongod &>> $LOGFILE
VALIDATE "enabling mongodb"

# Start MongoDB service
systemctl start mongod &>> $LOGFILE
VALIDATE "starting mongodb"

# Modify bind IP in mongod.conf to allow connections from any IP
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> $LOGFILE
VALIDATE "configuring bind IP"

# Restart MongoDB service to apply changes
systemctl restart mongod &>> $LOGFILE
VALIDATE "restarting mongodb"
