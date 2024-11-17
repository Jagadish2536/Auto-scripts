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

dnf install nginx -y &>> $LOGFILE
VALIDATE &? "install nginx"

systemctl enable nginx &>> $LOGFILE
VALIDATE &? "enable nginx"

systemctl start nginx &>> $LOGFILE
VALIDATE &? "start nginx"

rm -rf /usr/share/nginx/html/* &>> $LOGFILE
VALIDATE &? "remove old data"

curl -o /tmp/web.zip https://roboshop-builds.s3.amazonaws.com/web.zip &>> $LOGFILE
VALIDATE &? "download data"

cd /usr/share/nginx/html

unzip -o /tmp/web.zip &>> $LOGFILE
VALIDATE &? "unzip data"

cp roboshop.conf /etc/nginx/default.d/roboshop.conf &>> $LOGFILE
VALIDATE &? "copy new data"

systemctl restart nginx &>> $LOGFILE
VALIDATE &? "restart nginx"