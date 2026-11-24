
# OPENVPN SERVER LAB – DEBIAN 13

## 1. System Information

- Server: HP ProBook 440 G1
- Operating System: Debian 13 (Trixie)
- Username: NAME
- OpenVPN Version: 2.6.14
- Easy-RSA Version: 3.2.2

## 2. Install OpenVPN and Easy-RSA

```bash
sudo apt install openvpn easy-rsa -y
```

## 3. Create the Easy-RSA Working Directory

```bash
make-cadir ~/openvpn-ca
cd ~/openvpn-ca
```

## 4. Initialize the PKI

```bash
./easyrsa init-pki
```

## 5. Build the Certificate Authority (CA)

```bash
./easyrsa build-ca
```

Configuration:
- CA Passphrase: User-defined password.
- Common Name (CN): NAME-OPENVPN-CA

## 6. Verify the CA Files

```bash
ls -lh pki/ca.crt pki/private/ca.key
```

Generated files:
- `pki/ca.crt` – CA Certificate
- `pki/private/ca.key` – CA Private Key

## 7. Generate the Server Private Key and CSR

```bash
./easyrsa gen-req NAME-VPN-SERVER nopass
```

Common Name: `NAME-VPN-SERVER`

Generated files:
- `pki/reqs/NAME-VPN-SERVER.req`
- `pki/private/NAME-VPN-SERVER.key`

## 8. Sign the Server Certificate

```bash
./easyrsa sign-req server NAME-VPN-SERVER
```

Input:
- Confirmation: `yes`
- CA Passphrase: Enter the CA password.

Generated file:
- `pki/issued/NAME-VPN-SERVER.crt`

## 9. Generate Diffie-Hellman Parameters

```bash
./easyrsa gen-dh
```

Verify the file:

```bash
ls -lh pki/dh.pem
```

## 10. Verify DH Parameters

```bash
openssl dhparam -in pki/dh.pem -text -noout | head -5
```

Expected output:

```text
DH Parameters: (2048 bit)
```

## 11. Generate the Client Private Key and CSR

```bash
./easyrsa gen-req NAME-CLIENT nopass
```

Common Name: `NAME-CLIENT`

Generated files:
- `pki/reqs/NAME-CLIENT.req`
- `pki/private/NAME-CLIENT.key`

## 12. Verification Commands

Check OpenVPN version:

```bash
openvpn --version
```

Check OpenVPN service status:

```bash
systemctl status openvpn --no-pager
```

Check network interfaces:

```bash
ip -br addr
```

Verify CA files:

```bash
ls -lh pki/ca.crt pki/private/ca.key
```

Verify DH parameters:

```bash
openssl dhparam -in pki/dh.pem -text -noout | head -5
```

## 13. Project Progress

| Component | Status |
|---|---|
| OpenVPN Installation | Completed |
| Easy-RSA Installation | Completed |
| PKI Initialization | Completed |
| CA Certificate | Completed |
| CA Private Key | Completed |
| Server Private Key | Completed |
| Server CSR | Completed |
| Server Certificate | Signed |
| DH Parameters | Generated – 2048-bit |
| Client Private Key | Completed |
| Client CSR | Completed |
| Client Certificate | Not Signed |
| Server Configuration | Not Created |
| VPN Server Deployment | Not Started |

## 14. Next Implementation Steps

1. Sign the Client Certificate.
2. Generate the TLS key.
3. Create the OpenVPN Server configuration.
4. Configure IP forwarding and routing.
5. Configure the firewall.
6. Start the OpenVPN Server service.
7. Configure the VPN Client.
8. Establish the VPN connection.
9. Test connectivity between VPN clients and the server.

## 15. Security Considerations

- Never share the CA Private Key.
- Never upload private keys to public GitHub repositories.
- Never disclose the CA passphrase.
- Restrict access to files inside `pki/private/`.
- Keep backups of the CA files in a secure location.
