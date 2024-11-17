#!/bin/bash

# Define color codes for output
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"  # Reset color

# Define MySQL IP address
MYSQLIP=172.31.32.123

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

# Install Maven
dnf install maven -y &>> $LOGFILE
VALIDATE $? "Installing Maven"

# Check if roboshop user exists, if not, create it
id roboshop &>> $LOGFILE
if [ $? -ne 0 ]; then
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "${Y}roboshop user already exists, skipping user creation${N}"
fi

# Copy the shipping.service file to systemd directory
cp shipping.service /etc/systemd/system/shipping.service &>> $LOGFILE
VALIDATE $? "Copying shipping.service"

# Create the /app directory
mkdir -p /app &>> $LOGFILE
VALIDATE $? "Creating /app directory"

# Download the shipping.zip file
curl -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip &>> $LOGFILE
VALIDATE $? "Downloading shipping.zip"

# Unzip the downloaded shipping.zip file
cd /app
unzip -o /tmp/shipping.zip &>> $LOGFILE
VALIDATE $? "Unzipping shipping.zip"

# Clean and package the Maven project
mvn clean package &>> $LOGFILE
VALIDATE $? "Maven clean package"

# Move the packaged JAR file
mv target/shipping-1.0.jar shipping.jar &>> $LOGFILE
VALIDATE $? "Moving packaged JAR file"

# Reload systemd to apply the new service
systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Reloading systemd daemon"

# Enable the shipping service
systemctl enable shipping &>> $LOGFILE
VALIDATE $? "Enabling shipping service"

# Start the shipping service
systemctl start shipping &>> $LOGFILE
VALIDATE $? "Starting shipping service"

# Install MySQL
dnf install mysql -y &>> $LOGFILE
VALIDATE $? "Installing MySQL"

# Connect to MySQL and run the schema script
mysql -h $MYSQLIP -uroot -pRoboShop@1 < /app/schema/shipping.sql &>> $LOGFILE
VALIDATE $? "Running schema on MySQL"

# Restart the shipping service after MySQL setup
systemctl restart shipping &>> $LOGFILE
VALIDATE $? "Restarting shipping service"
