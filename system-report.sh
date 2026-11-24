#!/bin/bash

echo "===== SYSTEM REPORT ====="

echo ""
echo "Hostname:"
hostname

echo ""
echo "Operating System:"
cat /etc/os-release | grep PRETTY_NAME

echo ""
echo "Kernel:"
uname -r

echo ""
echo "CPU:"
lscpu | grep "Model name"

echo ""
echo "Memory:"
free -h

echo ""
echo "Disk:"
df -h

echo ""
echo "Uptime:"
uptime