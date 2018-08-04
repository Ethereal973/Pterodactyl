server_setup() {
    echo "Hope you enjoy this install script. https://thientran.io/"
    read -p "Enter admin email (admin@example.com) : " EMAIL
    read -p "Enter servername (panel.example.com) : " SERVERNAME
    read -p "Enter time zone (America/New_York) : " TIME
    read -p "Password : " PASS
}

initial() {
    echo "Updating your server!"
    apt -y update 
    apt -y upgrade
    apt -y autoremove
    apt -y autoclean
    apt -y install curl
}

install_dependencies(){
    echo "Installing dependencies"
    apt -y install software-properties-common
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    add-apt-repository -y ppa:chris-lea/redis-server
    apt -y update
    apt -y upgrade
    apt -y install php7.2 php7.2-cli php7.2-gd php7.2-mysql php7.2-pdo php7.2-mbstring php7.2-tokenizer php7.2-bcmath php7.2-xml php7.2-fpm php7.2-curl php7.2-zip nginx curl tar unzip git redis-server
}

install_mariadb() {
    echo "Installing Mariadb Server v10.3 - Ubuntu 18.04."
    apt install software-properties-common
    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
    add-apt-repository 'deb [arch=amd64,arm64,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu bionic main'
    rootpasswd=$(openssl rand -base64 12)
    export DEBIAN_FRONTEND="noninteractive"
    sudo aptitude -y install mariadb-server
    echo "root password is $rootpasswd"
}

mariadb_setup() {
    echo "Setting up your database."
    password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`  
    Q1="CREATE DATABASE IF NOT EXISTS pterodactyl;"
    Q2="GRANT ALL ON *.* TO 'panel'@'127.0.0.1' IDENTIFIED BY '$password';"
    Q3="FLUSH PRIVILEGES;"
    SQL="${Q1}${Q2}${Q3}"
    
    sudo mysql -u root -p="" -e "$SQL"

    echo "Database 'pterodactyl' and user 'panel' created with password $password"
}
