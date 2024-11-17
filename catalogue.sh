#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[30m"
MONGODBIP=172.31.37.214

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
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is $R failed $N"
        exit 1
    else
        echo -e "$2 is $G sucess $N"
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

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip &>> $LOGFILE
VALIDATE &? "downloading data to database"

cd /app 

unzip -o /tmp/catalogue.zip &>> $LOGFILE
VALIDATE &? "unzip data"

cd /app

npm install &>> $LOGFILE
VALIDATE &? "install data"

cp catalogue.service /etc/systemd/system/catalogue.service &>> $LOGFILE
VALIDATE &? "copy catalouge service"

systemctl daemon-reload &>> $LOGFILE
VALIDATE &? "daemon reload"

systemctl enable catalogue &>> $LOGFILE
VALIDATE &? "enable catalogue"

systemctl start catalogue &>> $LOGFILE
VALIDATE &? "start catalogue"

cp mongodb.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE &? "creating mongo.repo"

dnf install mongodb-org-shell -y &>> $LOGFILE
VALIDATE &? "install mongodb-org-shell"

mongo --host $MONGODBIP </app/schema/catalogue.js &>> $LOGFILE
VALIDATE &? "connecting to mongodb server"