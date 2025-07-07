#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shellscript-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has not root priviliges or not
if [ $USERID -ne 0 ]
then 
   echo -e "$R ERROR:: Please run this  script with root access $N" | tee -a $LOG_FILE
   exit 1 #give other than 0 upto 127
else
   echo "You are running wit root access" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then 
       echo -e "Installing $2 is...$Y SUCCESS $N" | tee -a $LOG_FILE
    else
       echo -e "Installing $2 is...$R FAILURE $N" | tee -a $LOG_FILE
       exit 1
    fi 
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying MongoDB repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing mongodb services"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Editing MongoDB conf file for remote connections"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting MongoDB"