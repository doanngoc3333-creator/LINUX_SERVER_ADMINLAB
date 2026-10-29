curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable --now ssh
sudo tailscale up
