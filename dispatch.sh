#!/bin/bash

R="\e[31m"  # Red color for error
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

# Function to validate command success
VALIDATE() {
    if [ $? -ne 0 ]; then  # Check exit status of last command
        echo -e "${R}$2 failed${N}"  # Print failure in red
        exit 1
    else
        echo -e "${G}$2 success${N}"  # Print success in green
    fi
}

# Ensure unzip is installed
which unzip &>/dev/null || {
    echo "unzip not found, installing..."
    dnf install unzip -y &>> $LOGFILE
    VALIDATE $? "install unzip"
}

# Install Golang
dnf install golang -y &>> $LOGFILE
VALIDATE $? "installing golang"

# Check if the roboshop user exists, if not, create it
id roboshop &>> $LOGFILE
if [ $? -ne 0 ]; then
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "creating roboshop user"
else
    echo -e "roboshop user already exists. $Y skipping user creation. $N"
fi

# Copy the dispatch service file
cp dispatch.service /etc/systemd/system/dispatch.service &>> $LOGFILE
VALIDATE $? "copying dispatch service"

# Create application directory
mkdir -p /app &>> $LOGFILE
VALIDATE $? "creating /app directory"

# Download the dispatch.zip file
curl -L -o /tmp/dispatch.zip https://roboshop-builds.s3.amazonaws.com/dispatch.zip &>> $LOGFILE
VALIDATE $? "downloading dispatch.zip"

# Unzip the dispatch.zip file
cd /app
unzip -o /tmp/dispatch.zip &>> $LOGFILE
VALIDATE $? "unzipping dispatch.zip"

# Initialize Go module if it doesn't exist
if [ ! -f "go.mod" ]; then
    go mod init dispatch &>> $LOGFILE
    VALIDATE $? "initializing Go module"
fi

# Download Go dependencies
go get &>> $LOGFILE
VALIDATE $? "downloading Go dependencies"

# Build the Go application
go build &>> $LOGFILE
VALIDATE $? "building Go application"

# Reload systemd to apply new service
systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "reloading systemd daemon"

# Enable dispatch service to start on boot
systemctl enable dispatch &>> $LOGFILE
VALIDATE $? "enabling dispatch service"

# Start the dispatch service
systemctl start dispatch &>> $LOGFILE
VALIDATE $? "starting dispatch service"
