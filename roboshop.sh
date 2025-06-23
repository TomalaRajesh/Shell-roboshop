#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-00f85c25da2a97507"
INSTANCES=("mongodb" "reds" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z061750233024S3H4FMKY"
DOMAIN_NAME="rajdevops.fun"

for instance in "${INSTANCES[@]}"
do
  echo "Launching instance: $instance"

  # 1. Launch instance and capture the actual EC2 instance ID
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[0].InstanceId" \
    --output text)

  echo "$instance EC2 instance ID: $INSTANCE_ID"

  # 2. Optional: Wait until instance is running
  aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

  # 3. Get private or public IP based on instance type
  if [ "$instance" != "frontend" ]; then
    IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PrivateIpAddress" \
      --output text)
  else
    IP=$(aws ec2 describe-instances \
      --instance-ids "$INSTANCE_ID" \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text)
  fi

  echo "$instance IP address: $IP"

  # 4. Validate IP
  if [[ -z "$IP" || ! "$IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "❌ Invalid IP for $instance. Skipping DNS update."
    continue
  fi

  # 5. Create or update DNS record
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Comment\": \"Creating or updating record set for $instance\",
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"${instance}.${DOMAIN_NAME}.\",
          \"Type\": \"A\",
          \"TTL\": 60,
          \"ResourceRecords\": [{
            \"Value\": \"${IP}\"
          }]
        }
      }]
    }"

done
