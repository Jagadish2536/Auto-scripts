#!/bin/bash

R="\e[31m"  # Red color for error
G="\e[32m"  # Green color for success
Y="\e[33m"  # Yellow color for warnings
N="\e[0m"   # Reset color
MONGODBIP=172.31.37.214  # MongoDB IP

TIME=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIME.log"

ID=$(id -u)

# Check if the script is run as root
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

# Disable Node.js module and enable Node.js 18
dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:18 -y &>> $LOGFILE
VALIDATE $? "enabling nodejs 18"

# Install Node.js
dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "installing nodejs 18"

# Check if roboshop user exists, create if not
id roboshop &>> $LOGFILE
if [ $? -ne 0 ]; then
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "creating roboshop user"
else
    echo -e "roboshop user already exists. $Y skipping user creation. $N"
fi

# Create application directory
mkdir -p /app &>> $LOGFILE
VALIDATE $? "creating /app directory"

# Download catalogue.zip
curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip &>> $LOGFILE
VALIDATE $? "downloading catalogue.zip"

# Unzip catalogue.zip
cd /app
unzip -o /tmp/catalogue.zip &>> $LOGFILE
VALIDATE $? "unzipping catalogue.zip"

# Install Node.js dependencies
npm install &>> $LOGFILE
VALIDATE $? "installing Node.js dependencies"

# Copy systemd service file for catalogue
cp catalogue.service /etc/systemd/system/catalogue.service &>> $LOGFILE
VALIDATE $? "copying catalogue service"

# Reload systemd daemon
systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "reloading systemd daemon"

# Enable and start the catalogue service
systemctl enable catalogue &>> $LOGFILE
VALIDATE $? "enabling catalogue service"

systemctl start catalogue &>> $LOGFILE
VALIDATE $? "starting catalogue service"

# MongoDB repository configuration
cp mongodb.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE $? "creating mongo.repo"

# Install MongoDB shell (if you only need the shell, not the full server)
dnf install mongodb-org-shell -y &>> $LOGFILE
VALIDATE $? "installing mongodb-org-shell"

# Connect to MongoDB and execute the schema script
mongo --host $MONGODBIP </app/schema/catalogue.js &>> $LOGFILE
VALIDATE $? "executing MongoDB schema"
