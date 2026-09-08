#!/bin/bash
# Lists all EC2 instances and their current state using AWS CLI
# Then filters to show only "running" instances
 
instance_ids=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output text)
 
for id in $instance_ids
do
    state=$(aws ec2 describe-instances --instance-ids $id --query 'Reservations[0].Instances[0].State.Name' --output text)
    echo "Instance $id ka status: $state"
done
 
echo ""
echo "--- Sirf running instances (grep filter) ---"
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output text | grep running
 
