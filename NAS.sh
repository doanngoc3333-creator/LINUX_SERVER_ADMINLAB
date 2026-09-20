sudo apt update && sudo apt install samba -y
mkdir -p #path of NAS directory
sudo nano /etc/samba/smb.conf
# nano open
[MyNAS]
path = #paste path of NAS directory
browsable = yes
writable = yes
read only = no
valid users = name of user #in this NAS
#nano closing 
sudo systemctl status smbd # checking samba
sudo ufw allow samba
sudo smbpasswd -a username
#enter password and retype
ip a #check IP


#On other computer, open file thunnar/explorer
smb://IP_ADDRESS/MyNAS #example 


