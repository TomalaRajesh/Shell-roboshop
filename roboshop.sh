#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-00f85c25da2a97507" #Security group ID in instance details
INSTANCES=("mongodb" "reds" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z061750233024S3H4FMKY" # Route53 --> Hosted zone ID
DOMAIN_NAME="rajdevops.fun"

for instance in ${INSTANCES[@]}
do
    INSTANCES_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-00f85c25da2a97507 --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=test}]" --query "Instances[0].PrivateIpAddress" --output text)
    if  [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCES_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCES_ID --query "Reservations[0].Instances[0].PublicIPAddress" --output text)
    fi
    echo "$instance IP address: $IP"

    aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '
  {
    "Comment": "Creating or updating record set for cognito endpoint"
    ,"Changes": [{
      "Action"              : "UPSERT"
      ,"ResourceRecordSet"  : {
        "Name"              : "'$instance'.'$DOMAIN_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "'$IP'"
        }]
      }
    }]
  }'

done