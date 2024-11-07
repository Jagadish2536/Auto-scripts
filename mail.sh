#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[30m"

GMAIL=jagadishvarma99@gmail.com
AppPassword=12345678

DATA=relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_sasl_tls_security_options = noanonymous

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

yum update -y --exclude=kernel* &>> $LOGFILE
VALIDATE &? "Updating the Kernel"

yum -y install postfix cyrus-sasl-plain mailx  &>> $LOGFILE
VALIDATE &? "instaling postfix"

systemctl restart postfix &>> $LOGFILE
VALIDATE &? "Restart postfix"

systemctl enable postfix &>> $LOGFILE
VALIDATE &? "Enable the postfix"

sed -i -e '$a\'$'\n''$DATA' /etc/postfix/main.cf &>> $LOGFILE
VALIDATE &? "data copy"

touch /etc/postfix/sasl_passwd &>> $LOGFILE
VALIDATE &? "creating file sasl_passwd"

sed -e '1 a [smtp.gmail.com]:587 $GMAIL:$AppPassword' /etc/postfix/sasl_passwd &>> $LOGFILE
VALIDATE &? "setting sasl_passwd"

postmap /etc/postfix/sasl_passwd &>> $LOGFILE
VALIDATE &? "postmap lookup table"