#!/bin/bash
echo "===== NETWORK CHECK ====="
echo "" 
echo "Host information: "
ip a 
echo "" 
echo "IP address: "
hostname -I
echo ""
echo "Checking connection: "
ping 8.8.8.8
