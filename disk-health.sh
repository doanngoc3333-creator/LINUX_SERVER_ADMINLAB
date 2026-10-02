#!/bin/bash
echo "===== DISK HEALTH CHECK ====="
echo "" 
echo "Disk information: "
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
echo "" 
echo "Disk usage: "
df -h
echo "" 
df -i
echo ""
echo "Partition: "
findmnt -D
echo ""
echo "SMART status: "
sudo smartctl -a /dev/sda
echo ""
sudo smartctl -a /dev/sdc
echo ""
sudo smartctl -a /dev/sdb