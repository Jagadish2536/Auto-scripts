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

curl -s https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash &>> $LOGFILE
VALIDATE &? "Configure YUM Repos from the script provided by vendor"

curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash &>> $LOGFILE
VALIDATE &? "Configure YUM Repos for RabbitMQ"

dnf install rabbitmq-server -y &>> $LOGFILE
VALIDATE &? "Install RabbitMQ"

systemctl enable rabbitmq-server &>> $LOGFILE
VALIDATE &? "enable RabbitMQ Service"

systemctl start rabbitmq-server &>> $LOGFILE
VALIDATE &? "Start RabbitMQ Service"

rabbitmqctl add_user roboshop roboshop123 &>> $LOGFILE
VALIDATE &? "changing password"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOGFILE
VALIDATE &? "set permissions"