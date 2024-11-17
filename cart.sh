#!/bin/bash

R="\e[31m"  # Red color for errors
G="\e[32m"  # Green color for success
Y="\e[33m"  # Yellow color for warnings
N="\e[0m"   # Reset color

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

# Function to validate the success of a command
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

# Install Node.js 18
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

# Copy systemd service file for user
cp cart.service /etc/systemd/system/cart.service &>> $LOGFILE
VALIDATE $? "copying user service"

# Create application directory
mkdir -p /app &>> $LOGFILE
VALIDATE $? "creating /app directory"

# Download cart.zip file
curl -L -o /tmp/cart.zip https://roboshop-builds.s3.amazonaws.com/cart.zip &>> $LOGFILE
VALIDATE $? "downloading cart.zip"

# Unzip cart.zip into /app
cd /app
unzip -o /tmp/cart.zip &>> $LOGFILE
VALIDATE $? "unzipping cart.zip"

# Install Node.js dependencies
npm install &>> $LOGFILE
VALIDATE $? "installing Node.js dependencies"

# Reload systemd daemon
systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "reloading systemd daemon"

# Enable the cart service to start on boot
systemctl enable cart &>> $LOGFILE
VALIDATE $? "enabling cart service"

# Start the cart service
systemctl start cart &>> $LOGFILE
VALIDATE $? "starting cart service"
