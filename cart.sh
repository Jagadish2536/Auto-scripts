#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[30m"

TIME=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIME.log"

ID=$(id -u)

if [ $ID -ne 0 ]
then
    echo "You are not root user"
    exit 1
else
    echo "You are a root user"
fi

VALIDATE() {
    if [ $1 -ne 0 ]; 
    then
        echo -e "${R}$2 is failed${N}"
        exit 1
    else
        echo -e "${G}$2 is success${N}"
    fi
}

dnf module disable nodejs -y &>> $LOGFILE
VALIDATE &? "disabling nodejs"

dnf module enable nodejs:18 -y &>> $LOGFILE
VALIDATE &? "enabling nodejs 18"

dnf install nodejs -y &>> $LOGFILE
VALIDATE &? "installing nodejs 18"

id roboshop &>> $LOGFILE
if [ $? -ne 0 ]
then
    useradd roboshop &>> $LOGFILE
    VALIDATE &? "user add"
else
    echo -e "roboshop user already exist $Y skip $N"
fi

mkdir -p /app &>> $LOGFILE
VALIDATE &? "making directory"

curl -L -o /tmp/cart.zip https://roboshop-builds.s3.amazonaws.com/cart.zip &>> $LOGFILE
VALIDATE &? "downloading data to database"

cd /app 

unzip -o /tmp/cart.zip &>> $LOGFILE
VALIDATE &? "unzip data"

cd /app

npm install &>> $LOGFILE
VALIDATE &? "install data"

systemctl daemon-reload &>> $LOGFILE
VALIDATE &? "daemon reload"

systemctl enable cart &>> $LOGFILE
VALIDATE &? "enable ccart"

systemctl start cart &>> $LOGFILE
VALIDATE &? "start ccart"