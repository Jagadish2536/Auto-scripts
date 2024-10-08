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

dnf module disable mysql -y &>> $LOGFILE
VALIDATE &? "disable mysql"

cp mysql.repo /etc/yum.repos.d/mysql.repo &>> $LOGFILE
VALIDATE &? "creating mysql.repo"

dnf install mysql-community-server -y &>> $LOGFILE
VALIDATE &? "installing mysql"

systemctl enable mysqld &>> $LOGFILE
VALIDATE &? "enabling mysql"

systemctl start mysqld &>> $LOGFILE
VALIDATE &? "starting mysql"

mysql_secure_installation --set-root-pass RoboShop@1 &>> $LOGFILE
VALIDATE &? "password changed for mysql"

mysql -uroot -pRoboShop@1 &>> $LOGFILE
VALIDATE &? "password is working or not"