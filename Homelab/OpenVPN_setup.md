# OpenVPN Server Lab – Debian 13
## Complete Command Collection

A reusable collection of commands for installing, configuring, deploying and testing an OpenVPN server.

All names and network addresses are generic examples.

---

# 1. Install OpenVPN and Easy-RSA

```bash
sudo apt update
sudo apt install openvpn easy-rsa nftables -y
```

Check versions:

```bash
openvpn --version
```

---

# 2. Create the Easy-RSA Directory

```bash
make-cadir ~/openvpn-ca
cd ~/openvpn-ca
```

Initialize PKI:

```bash
./easyrsa init-pki
```

---

# 3. Create the Certificate Authority

```bash
./easyrsa build-ca
```

Example Common Name:

```text
VPN-LAB-CA
```

Check CA files:

```bash
ls -lh pki/ca.crt pki/private/ca.key
```

---

# 4. Generate the Server Key and Certificate

Generate server key and CSR:

```bash
./easyrsa gen-req vpn-server nopass
```

Sign the server certificate:

```bash
./easyrsa sign-req server vpn-server
```

Generated files:

```text
pki/reqs/vpn-server.req
pki/private/vpn-server.key
pki/issued/vpn-server.crt
```

---

# 5. Generate Diffie-Hellman Parameters

```bash
./easyrsa gen-dh
```

Check DH parameters:

```bash
openssl dhparam -in pki/dh.pem -text -noout | head -5
```

---

# 6. Generate the Client Key and Certificate

Generate client key and CSR:

```bash
./easyrsa gen-req vpn-client nopass
```

Sign the client certificate:

```bash
./easyrsa sign-req client vpn-client
```

Generated files:

```text
pki/reqs/vpn-client.req
pki/private/vpn-client.key
pki/issued/vpn-client.crt
```

---

# 7. Create the OpenVPN Server Directory

```bash
sudo install -d -m 700 /etc/openvpn/server
```

Generate TLS authentication key:

```bash
sudo openvpn --genkey secret /etc/openvpn/server/ta.key
```

---

# 8. Install Server Certificates and Keys

```bash
cd ~/openvpn-ca

sudo install -m 644 pki/ca.crt \
/etc/openvpn/server/ca.crt

sudo install -m 644 pki/dh.pem \
/etc/openvpn/server/dh.pem

sudo install -m 644 pki/issued/vpn-server.crt \
/etc/openvpn/server/server.crt

sudo install -m 600 pki/private/vpn-server.key \
/etc/openvpn/server/server.key
```

Set ownership:

```bash
sudo chown root:root /etc/openvpn/server/*
```

---

# 9. Create the Server Configuration

```bash
sudo tee /etc/openvpn/server/server.conf > /dev/null <<'EOF'
port 1194
proto udp
dev tun

user nobody
group nogroup

persist-key
persist-tun

topology subnet
server 10.8.0.0 255.255.255.0

keepalive 10 120

dh dh.pem
ca ca.crt
cert server.crt
key server.key

tls-auth ta.key 0

auth SHA256
data-ciphers AES-256-GCM:AES-128-GCM

tls-version-min 1.2

verb 3
EOF
```

---

# 10. Enable IP Forwarding

```bash
sudo tee /etc/sysctl.d/99-openvpn.conf > /dev/null <<'EOF'
net.ipv4.ip_forward=1
EOF

sudo sysctl --system
```

---

# 11. Configure nftables

Install and enable:

```bash
sudo apt install nftables -y
sudo systemctl enable --now nftables
```

Create firewall table:

```bash
sudo nft add table inet openvpn
```

Create input chain:

```bash
sudo nft 'add chain inet openvpn input {
    type filter hook input priority 0;
    policy accept;
}'
```

Allow UDP 1194:

```bash
sudo nft add rule inet openvpn input udp dport 1194 accept
```

Note: This is a basic lab rule. Production deployments require a complete firewall and forwarding policy.

---

# 12. Start the OpenVPN Server

```bash
sudo systemctl enable --now openvpn-server@server
```

Restart:

```bash
sudo systemctl restart openvpn-server@server
```

Check service:

```bash
sudo systemctl is-active openvpn-server@server
```

Expected output:

```text
active
```

---

# 13. Verify the Server

Check UDP port:

```bash
sudo ss -lunp | grep ':1194'
```

Check tunnel interface:

```bash
ip -br addr show tun0
```

Check service logs:

```bash
sudo journalctl -u openvpn-server@server -n 50 --no-pager
```

Check IP forwarding:

```bash
sysctl net.ipv4.ip_forward
```

Expected output:

```text
net.ipv4.ip_forward = 1
```

---

# 14. Create the Client Directory

```bash
mkdir -p ~/openvpn-client
cd ~/openvpn-ca
```

Copy client files:

```bash
cp pki/ca.crt ~/openvpn-client/ca.crt

cp pki/issued/vpn-client.crt \
~/openvpn-client/client.crt

cp pki/private/vpn-client.key \
~/openvpn-client/client.key
```

Copy TLS key:

```bash
sudo install -m 600 \
-o "$(id -un)" -g "$(id -gn)" \
/etc/openvpn/server/ta.key \
~/openvpn-client/ta.key
```

Protect client private files:

```bash
chmod 600 ~/openvpn-client/client.key
chmod 600 ~/openvpn-client/ta.key
```

---

# 15. Generate the Client Configuration

Replace `SERVER_ADDRESS` with the server IP address or hostname.

```bash
cat > ~/openvpn-client/client.ovpn <<'EOF'
client
dev tun
proto udp

remote SERVER_ADDRESS 1194

resolv-retry infinite
nobind
persist-key
persist-tun

remote-cert-tls server

auth SHA256
data-ciphers AES-256-GCM:AES-128-GCM

tls-version-min 1.2
key-direction 1

verb 3

ca ca.crt
cert client.crt
key client.key

tls-auth ta.key 1
EOF

chmod 600 ~/openvpn-client/client.ovpn
```

---

# 16. Create a Single-File Client Profile

This script embeds the certificates and keys into one `.ovpn` file.

```bash
cd ~/openvpn-client

{
cat <<'EOF'
client
dev tun
proto udp
remote SERVER_ADDRESS 1194

resolv-retry infinite
nobind
persist-key
persist-tun

remote-cert-tls server

auth SHA256
data-ciphers AES-256-GCM:AES-128-GCM

tls-version-min 1.2
key-direction 1

verb 3

<ca>
EOF

cat ca.crt

echo '</ca><cert>'
cat client.crt

echo '</cert><key>'
cat client.key

echo '</key><tls-auth>'
cat ta.key

echo '</tls-auth>'

} > client.ovpn

chmod 600 client.ovpn
```

---

# 17. Tailscale Integration

Use Tailscale as an additional network transport.

Client configuration example:

```text
remote SERVER_TAILSCALE_IP 1194
```

Both devices must be connected to the same authorized Tailscale network.

Architecture:

```text
VPN Client
    |
    | Tailscale
    |
    v
VPN Server
    |
    | OpenVPN UDP 1194
    |
    v
Encrypted VPN Tunnel
```

Tailscale provides device connectivity. OpenVPN provides a separate VPN tunnel.

---

# 18. Client Connection

Install OpenVPN on the client:

```bash
sudo apt update
sudo apt install openvpn -y
```

Connect:

```bash
sudo openvpn --config client.ovpn
```

Expected successful log message:

```text
Initialization Sequence Completed
```

This message indicates that the OpenVPN tunnel has been established.

---

# 19. Client Connectivity Tests

Check tunnel interface:

```bash
ip -br addr show tun0
```

Check VPN server connectivity:

```bash
ping -c 4 10.8.0.1
```

Check routing table:

```bash
ip route
```

A successful tunnel connection should create a VPN network interface and install the required routes.

---

# 20. Useful Server Management Commands

Start server:

```bash
sudo systemctl start openvpn-server@server
```

Stop server:

```bash
sudo systemctl stop openvpn-server@server
```

Restart server:

```bash
sudo systemctl restart openvpn-server@server
```

Check status:

```bash
sudo systemctl status openvpn-server@server --no-pager
```

View logs:

```bash
sudo journalctl -u openvpn-server@server -f
```

Check listening port:

```bash
sudo ss -lunp | grep ':1194'
```

Check VPN interface:

```bash
ip addr show tun0
```

---

# 21. Certificate Revocation

Generate a Certificate Revocation List:

```bash
cd ~/openvpn-ca
./easyrsa gen-crl
```

Install it:

```bash
sudo install -m 644 pki/crl.pem \
/etc/openvpn/server/crl.pem
```

Add this line to `server.conf`:

```text
crl-verify crl.pem
```

To revoke a client certificate:

```bash
./easyrsa revoke vpn-client
./easyrsa gen-crl
```

Install the updated CRL again after revocation.

---

# 22. Important Security Rules

- Never publish `ca.key`.
- Never publish server or client private keys.
- Never publish the CA passphrase.
- Never commit `.ovpn` files containing private credentials.
- Use separate certificates for different clients.
- Protect `/etc/openvpn/server/`.
- Back up the CA securely.
- Use a proper firewall policy before production deployment.

---

# 23. Project Architecture

```text
                  OpenVPN SERVER
                  Debian 13
                       |
              +--------+--------+
              |                 |
          CA Certificate    Server Key
              |                 |
              +--------+--------+
                       |
                 OpenVPN Service
                    UDP 1194
                       |
                VPN Network
                 10.8.0.0/24
                       |
                +------+------+
                |             |
            Client 01     Client 02
                |             |
           Certificate    Certificate
                |             |
                +------+------+
                       |
                 Secure VPN
                  Connection
```

---

# 24. Project Status

| Task | Status |
|---|---|
| Install OpenVPN | Completed |
| Install Easy-RSA | Completed |
| Initialize PKI | Completed |
| Create CA | Completed |
| Generate server key | Completed |
| Create server certificate | Completed |
| Generate DH parameters | Completed |
| Generate client key | Completed |
| Create client certificate | Existing |
| Generate TLS key | Completed |
| Configure server | Completed |
| Enable IP forwarding | Configured |
| Add firewall rule | Added |
| Start OpenVPN service | Active |
| Verify UDP 1194 | Confirmed |
| Test client connection | Pending |
| Test VPN communication | Pending |
| Configure production routing | Pending |

---

# 25. Repository Security

Recommended `.gitignore`:

```gitignore
# Private keys
*.key
*.pem

# Client credentials
*.ovpn

# Easy-RSA private data
pki/private/
pki/issued/
pki/reqs/
pki/index.txt*
pki/serial*
pki/crl.pem

# Secrets
.env
.env.*
secrets/
credentials/

# Backups
*.bak
*.backup
*.old
```

**Repository rule:** Publish scripts and generic examples only. Keep all real certificates, private keys, passwords and deployment-specific network information outside Git.