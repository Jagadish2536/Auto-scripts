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

# Install dependencies (Python 3.6, GCC, python3-devel)
dnf install python36 gcc python3-devel -y &>> $LOGFILE
VALIDATE $? "Installing dependencies (Python 3.6, GCC, python3-devel)"

# Check if the roboshop user exists, and create it if necessary
id roboshop &>> $LOGFILE
if [ $? -ne 0 ]; then
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "roboshop user already exists, skipping $Y"
fi

# Create /app directory
mkdir -p /app &>> $LOGFILE
VALIDATE $? "Creating /app directory"

# Download the payment zip file
curl -L -o /tmp/payment.zip https://roboshop-builds.s3.amazonaws.com/payment.zip &>> $LOGFILE
VALIDATE $? "Downloading payment.zip"

# Unzip the payment.zip file to /app
cd /app
unzip -o /tmp/payment.zip &>> $LOGFILE
VALIDATE $? "Unzipping payment.zip"

# Install Python dependencies from requirements.txt
cd /app
pip3.6 install -r requirements.txt &>> $LOGFILE
VALIDATE $? "Installing Python dependencies"

# Copy the payment service file to systemd folder
cp payment.service /etc/systemd/system/payment.service &>> $LOGFILE
VALIDATE $? "Copying payment service file"

# Reload systemd to pick up the new service
systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reloading systemd daemon"

# Enable the payment service to start on boot
systemctl enable payment &>> $LOGFILE
VALIDATE $? "Enabling payment service"

# Start the payment service
systemctl start payment &>> $LOGFILE
VALIDATE $? "Starting payment service"
