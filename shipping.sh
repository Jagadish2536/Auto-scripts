#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[30m"
MYSQLIP=172.31.32.123

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

dnf install maven -y &>> $LOGFILE
VALIDATE &? "unzip data"

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

curl -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip &>> $LOGFILE
VALIDATE &? "downloading data to database"

cd /app 

unzip -o /tmp/shipping.zip &>> $LOGFILE
VALIDATE &? "unzip data"

cd /app

mvn clean package &>> $LOGFILE
VALIDATE &? "clean package"

mv target/shipping-1.0.jar shipping.jar &>> $LOGFILE
VALIDATE &? "moving process"

cp shipping.service /etc/systemd/system/shipping.service &>> $LOGFILE
VALIDATE &? "copy shipping service"

systemctl daemon-reload &>> $LOGFILE
VALIDATE &? "daemon reload"

systemctl enable shipping  &>> $LOGFILE
VALIDATE &? "enable shipping"

systemctl start shipping &>> $LOGFILE
VALIDATE &? "start shipping"

dnf install mysql -y &>> $LOGFILE
VALIDATE &? "start shipping"

mysql -h $MYSQLIP -uroot -pRoboShop@1 < /app/schema/shipping.sql &>> $LOGFILE
VALIDATE &? "connecting to mysql"

systemctl restart shipping &>> $LOGFILE
VALIDATE &? "restart shipping"