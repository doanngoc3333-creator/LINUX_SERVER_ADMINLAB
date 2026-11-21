# NGINX (ENGINE X)
* high performance ,open source web server and reverse proxy
## Core function
* Web server: delivering static files
* Reverse proxy: accepting client requests then sends to backend
## Troubleshooting

### Problem: NGINX failed to start

Error:
`"fastcgi_pass" directive is not allowed here`

Cause:
* The `fastcgi_pass` directive was placed outside the `location` block.
* The PHP `location` block was accidentally commented out.

Fix:
* Restore the `location ~ \.php$ { ... }` block.
* Keep `fastcgi_pass` inside the `location` block.
* Run `nginx -t` to validate the configuration.
* Restart NGINX after the configuration test passes.
### Problem: Duplicate default server

Error:
`a duplicate default server for 0.0.0.0:80`

Cause:
* A backup file (`default.bak`) was placed inside `/etc/nginx/sites-enabled/`.
* NGINX loaded the backup as an active configuration file.

Fix:
* Remove the backup file from `sites-enabled`.
* Keep backup files outside the active configuration directory.