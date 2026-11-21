#!/bin/bash

echo "[1/4] Updating system..."
sudo apt update

echo "[2/4] Upgrading system..."
sudo apt upgrade -y

echo "[3/4] Installing packages..."
sudo apt install -y \
curl wget git vim nano htop unzip tree jq \
openssh-server ufw fail2ban chrony rsync \
smartmontools nvme-cli parted gdisk \
nginx samba \
default-jdk default-jre \
php php-cli php-fpm \
python3 python3-pip python3-venv \
nodejs npm \
build-essential

echo "[4/4] Installation completed."

echo "=== DONE ==="#!/bin/bash
sudo apt install -y curl wget git
