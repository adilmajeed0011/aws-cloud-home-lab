#!/bin/bash
# Simple server health check script
# Prints current date/time and warns if root disk usage is over 80%
 
echo "Aaj ki date aur time:"
date
 
echo "Disk space:"
df -h
 
usage_number=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
 
if [ $usage_number -gt 80 ]
then
    echo "WARNING: Disk 80% se zyada bhar gayi hai!"
else
    echo "Sab theek hai, disk space kaafi hai."
fi
 
