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

dnf install golang -y &>> $LOGFILE
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

curl -L -o /tmp/dispatch.zip https://roboshop-builds.s3.amazonaws.com/dispatch.zip &>> $LOGFILE
VALIDATE &? "downloading data to database"

cd /app 

unzip -o /tmp/dispatch.zip &>> $LOGFILE
VALIDATE &? "unzip data"

cd /app

go mod init dispatch &>> $LOGFILE
VALIDATE &? "go mod"

go get &>> $LOGFILE
VALIDATE &? "go get"

go build &>> $LOGFILE
VALIDATE &? "go build"

cp dispatch.service /etc/systemd/system/dispatch.service &>> $LOGFILE
VALIDATE &? "copy dispatch service"

systemctl daemon-reload &>> $LOGFILE
VALIDATE &? "daemon reload"

systemctl enable dispatch &>> $LOGFILE
VALIDATE &? "enable dispatch"

systemctl start dispatch &>> $LOGFILE
VALIDATE &? "start dispatch"