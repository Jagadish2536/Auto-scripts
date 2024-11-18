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

# Configure YUM repositories for Erlang
curl -s https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash &>> $LOGFILE
VALIDATE $? "Configuring YUM repos for Erlang"

# Configure YUM repositories for RabbitMQ
curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash &>> $LOGFILE
VALIDATE $? "Configuring YUM repos for RabbitMQ"

# Install RabbitMQ server
dnf install rabbitmq-server -y &>> $LOGFILE
VALIDATE $? "Installing RabbitMQ server"

# Enable RabbitMQ service to start on boot
systemctl enable rabbitmq-server &>> $LOGFILE
VALIDATE $? "Enabling RabbitMQ service"

# Start RabbitMQ service
systemctl start rabbitmq-server &>> $LOGFILE
VALIDATE $? "Starting RabbitMQ service"

# Wait for RabbitMQ service to initialize properly (optional, but recommended)
sleep 5

# Check if 'roboshop' user exists
id roboshop &>> $LOGFILE

# If user doesn't exist, create the user in RabbitMQ
if [ $? -ne 0 ]; then
    echo "Creating RabbitMQ user roboshop..." &>> $LOGFILE
    rabbitmqctl add_user roboshop roboshop123 &>> $LOGFILE
    VALIDATE $? "Adding RabbitMQ user"  # Validate if user was created successfully
else
    # If user exists, log that no action is needed
    echo -e "roboshop user already exists. $Y skipping user creation. $N" &>> $LOGFILE
fi


# Set permissions for the new user
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOGFILE
VALIDATE $? "Setting RabbitMQ user permissions"
