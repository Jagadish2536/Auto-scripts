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
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is $R failed $N"
        exit 1
    else
        echo -e "$2 is $G sucess $N"
    fi
}

cp mongodb.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE &? "creating mongo.repo"

dnf install mongodb-org -y  &>> $LOGFILE
VALIDATE &? "Install mongodb"

systemctl enable mongod &>> $LOGFILE
VALIDATE &? "enabling the mongodb"

systemctl start mongod &>> $LOGFILE
VALIDATE &? "starting the mongodb" 

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> $LOGFILE
VALIDATE &? "config"

systemctl restart mongod &>> $LOGFILE
VALIDATE &? "restart mongodb"
