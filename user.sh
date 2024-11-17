#!/bin/bash

# Define color codes for output
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"  # Reset color

# Define MongoDB IP address
MONGODBIP=172.31.37.214

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

# Disable Node.js module
dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "Disabling nodejs"

# Enable Node.js 18 module
dnf module enable nodejs:18 -y &>> $LOGFILE
VALIDATE $? "Enabling nodejs 18"

# Install Node.js 18
dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "Installing nodejs 18"

# Check if roboshop user exists, if not, create it
id roboshop &>> $LOGFILE
if [ $? -ne 0 ]; then
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "${Y}roboshop user already exists, skipping user creation${N}"
fi

# Create the application directory
mkdir -p /app &>> $LOGFILE
VALIDATE $? "Creating /app directory"

# Download the user.zip file
curl -L -o /tmp/user.zip https://roboshop-builds.s3.amazonaws.com/user.zip &>> $LOGFILE
VALIDATE $? "Downloading data for user service"

# Unzip the downloaded user.zip file
cd /app
unzip -o /tmp/user.zip &>> $LOGFILE
VALIDATE $? "Unzipping user.zip"

# Install required npm packages
npm install &>> $LOGFILE
VALIDATE $? "Installing npm packages"

# Copy the user.service file to systemd directory
cp user.service /etc/systemd/system/user.service &>> $LOGFILE
VALIDATE $? "Copying user service file"

# Reload systemd to apply the new service
systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reloading systemd daemon"

# Enable the user service
systemctl enable user &>> $LOGFILE
VALIDATE $? "Enabling user service"

# Start the user service
systemctl start user &>> $LOGFILE
VALIDATE $? "Starting user service"

# Copy MongoDB repo configuration
cp mongodb.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE $? "Creating mongo.repo"

# Install MongoDB shell
dnf install mongodb-org-shell -y &>> $LOGFILE
VALIDATE $? "Installing mongodb-org-shell"

# Connect to MongoDB and run the schema script
mongo --host $MONGODBIP </app/schema/user.js &>> $LOGFILE
VALIDATE $? "Connecting to MongoDB and running schema script"
