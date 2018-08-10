#!/bin/bash

server_setup() {
    clear
    output "Thank you for your purchase. Please enter the information below. "
    read -p "Enter admin email (e.g. admin@example.com) : " EMAIL
    read -p "Enter servername (e.g. portal.example.com) : " SERVNAME
    read -p "Enter time zone (e.g. America/New_York) : " TIME
    read -p "Portal password : " PANELPASS
}

initial() {
    output "Updating all packages"
    # update package and upgrade Ubuntu
    sudo apt-get -y update 
    sudo apt-get -y upgrade
    sudo apt-get -y autoremove
    sudo apt-get -y autoclean
}

server() {
    output "Adding repositories and PPAs"
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    add-apt-repository -y ppa:chris-lea/redis-server
    sudo apt-get -y install software-properties-common
    sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
    sudo add-apt-repository -y 'deb [arch=amd64,arm64,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu bionic main'

install_nginx() {
    output "Installing Nginx server."
    sudo apt-get -y install nginx
    sudo service nginx start
    sudo service cron start
}

install_mariadb() {
    output "Installing Mariadb Server."
    # create random password
    rootpasswd=$(openssl rand -base64 12)
    export DEBIAN_FRONTEND="noninteractive"
    sudo apt-get -y install mariadb-server
}

create_directory(){
    # adding user to group, creating dir structure, setting permissions
    sudo mkdir -p /var/www/pterodactyl
    sudo chown -R www-data:www-data *  /var/www/pterodactyl
}

install_dependencies() {
    output "Installing PHP and Dependencies."
    apt -y install php7.2 php7.2-cli php7.2-gd php7.2-mysql php7.2-pdo php7.2-mbstring php7.2-tokenizer php7.2-bcmath php7.2-xml php7.2-fpm php7.2-curl php7.2-zip curl tar unzip git redis-server
}

pterodactyl() {
    output "Install Pterodactyl-Panel."
    # Installing the Panel
    cd /var/www/pterodactyl
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.7.9/panel.tar.gz
    tar --strip-components=1 -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
    output "Environment Setup"
    cp .env.example .env
    composer install --no-dev --optimize-autoloader
    php artisan key:generate --force
    output "Unless you are using a remote caching server, hit Enter to use the default settings for redis host, port and password."
    php artisan p:environment:setup
    output "Database setup"
    password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`  
    Q1="CREATE DATABASE IF NOT EXISTS panel;"
    Q2="GRANT ALL ON *.* TO 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$password';"
    Q3="FLUSH PRIVILEGES;"
    SQL="${Q1}${Q2}${Q3}"
    
    sudo mysql -u root -p="" -e "$SQL"

    output "Database 'panel' and user 'pterodactyl' created with password $password ."
    
    php artisan p:environment:database 
    output "Mail Setup"
    php artisan p:environment:mail
    output "Database Setup"
    php artisan migrate --seed
    output "Create First User"
    php artisan p:user:make --email="$EMAIL" --password=$PANELPASS --admin=y
     

   output "Creating config files"
sudo bash -c 'cat > /etc/systemd/system/pteroq.service' <<-'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
# On some systems the user and group might be different.
# Some systems use `apache` as the user and group.
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
EOF
    output "Updating Supervisor"
    sudo supervisorctl reread
    sudo supervisorctl update
    sudo supervisorctl start pterodactyl-worker:*
    sudo systemctl enable supervisor.service
}

pterodactyl_nginx() {
    output "Creating webserver initial config file"

    sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
    output "Install LetsEncrypt and setting SSL"
    sudo service nginx stop
    sudo apt -y install certbot
    sudo certbot certonly --email "$EMAIL" --agree-tos -d "$SERVNAME"
    echo '
        server {
            listen 80;
            listen [::]:80;
            server_name '"${SERVNAME}"';
            return 301 https://$server_name$request_uri;
        }
        
        server {
            listen 443 ssl http2;
            listen [::]:443 ssl http2;
            server_name '"${SERVNAME}"';
        
            root /var/www/pterodactyl/public;
            index index.php;
        
            access_log /var/log/nginx/pterodactyl.app-accress.log;
            error_log  /var/log/nginx/pterodactyl.app-error.log error;
        
            # allow larger file uploads and longer script runtimes
            client_max_body_size 100m;
            client_body_timeout 120s;
            
            sendfile off;
        
            # strengthen ssl security
            ssl_certificate /etc/letsencrypt/live/'"${SERVNAME}"'/fullchain.pem;
            ssl_certificate_key /etc/letsencrypt/live/'"${SERVNAME}"'/privkey.pem;
            ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
            ssl_prefer_server_ciphers on;
            ssl_session_cache shared:SSL:10m;
            ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:ECDHE-RSA-AES128-GCM-SHA256:AES256+EECDH:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";
            ssl_dhparam /etc/ssl/certs/dhparam.pem;
        
            # Add headers to serve security related headers
            add_header Strict-Transport-Security "max-age=15768000; preload;";
            add_header X-Content-Type-Options nosniff;
            add_header X-XSS-Protection "1; mode=block";
            add_header X-Robots-Tag none;
            add_header Content-Security-Policy "frame-ancestors 'self'";
        
            location / {
                    try_files $uri $uri/ /index.php?$query_string;
              }
        
            location ~ \.php$ {
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
                fastcgi_index index.php;
                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_intercept_errors off;
                fastcgi_buffer_size 16k;
                fastcgi_buffers 4 16k;
                fastcgi_connect_timeout 300;
                fastcgi_send_timeout 300;
                fastcgi_read_timeout 300;
                include /etc/nginx/fastcgi_params;
            }
        
            location ~ /\.ht {
                deny all;
            }
        }
    ' | sudo -E tee /etc/nginx/sites-available/pterodactyl.conf >/dev/null 2>&1    

    sudo service nginx restart
}

pterodactyl_daemon() {
    output "Installing the daemon now! Almost done!!"
    sudo apt-get update -y
    sudo apt-get upgrade -y
    curl -sSL https://get.docker.com/ | sh
    sudo systemctl enable docker
    output "Installing Nodejs"
    curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
    sudo aptitude -y install nodejs
    output "Making sure we didnt miss any dependencies "
    sudo aptitude -y install tar unzip make gcc g++ python-minimal
    output "Ok really installing the daemon files now"
    sudo mkdir -p /srv/daemon /srv/daemon-data
    cd /srv/daemon
    curl -L https://github.com/pterodactyl/daemon/releases/download/v0.6.3/daemon.tar.gz
    tar --strip-components=1 -xzv
    npm install --only=production

sudo bash -c 'cat > /etc/systemd/system/wings.service' <<-'EOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service

[Service]
User=root
#Group=some_group
WorkingDirectory=/srv/daemon
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/bin/node /srv/daemon/src/index.js
Restart=on-failure
StartLimitInterval=600

[Install]
WantedBy=multi-user.target
EOF

      sudo systemctl daemon-reload
      sudo systemctl enable wings

# Process command line...
server_setup
initial
install_nginx
install_mariadb
install_dependencies
install_timezone
server
pterodactyl
pterodactyl_1
pterodactyl_niginx
pterodactyl_daemon
;;
esac
exit 1;
