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

dnf install python36 gcc python3-devel -y &>> $LOGFILE
VALIDATE &? "making directory"

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

curl -L -o /tmp/payment.zip https://roboshop-builds.s3.amazonaws.com/payment.zip &>> $LOGFILE
VALIDATE &? "downloading data to database"

cd /app 

unzip -o /tmp/payment.zip &>> $LOGFILE
VALIDATE &? "unzip data"

cd /app

pip3.6 install -r requirements.txt
VALIDATE &? "pip install"

cp payment.service /etc/systemd/system/payment.service &>> $LOGFILE
VALIDATE &? "copy payment service"

systemctl daemon-reload &>> $LOGFILE
VALIDATE &? "daemon reload"

systemctl enable payment &>> $LOGFILE
VALIDATE &? "enable payment"

systemctl start payment &>> $LOGFILE
VALIDATE &? "start payment"