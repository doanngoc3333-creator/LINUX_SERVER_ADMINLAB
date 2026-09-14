sudo rm -f /etc/nginx/sites-enabled/default.bak
sudo sed -i '56s/^#//' /etc/nginx/sites-enabled/default
sudo sed -i '60i\		fastcgi_pass unix:/run/php/php7.4-fpm.sock;' /etc/nginx/sites-enabled/default
sudo sed -i '63s/^#//' /etc/nginx/sites-enabled/default