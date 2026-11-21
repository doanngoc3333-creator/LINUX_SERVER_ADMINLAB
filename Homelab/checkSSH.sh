#!/bin/bash
if systemctl is-active --quiet ssh; then
    echo "SSH: RUNNING" #condition true
else
    echo "SSH: STOPPED"
fi
