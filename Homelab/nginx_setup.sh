sudo apt update
sudo apt install nginx


sudo systemctl status nginx
sudo nano /etc/nginx/sites-available/default

#INSIDE FILE
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;
    root path/toweb;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}

#EXIT FILE
sudo nginx -t #test is successful
sudo systemctl reload nginx 
sudo systemctl status nginx --no-pager #unreconized option
