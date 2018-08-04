server_setup() {
    echo "Hope you enjoy this install script. https://thientran.io"
    read -p "Enter admin email (admin@example.com) : " EMAIL
    read -p "Enter servername (panel.example.com) : " SERVERNAME
    read -p "Enter time zone (America/New_York) : " TIME
    read -p "Password : " PASS
}

initial() {
    echo "Updating your server!"
    sudo apt-get -y update 
    sudo apt-get -y upgrade
    sudo apt-get -y autoremove
    sudo apt-get -y autoclean
}

install_dependencies(){
    echo "Installing dependencies"
    apt-get -y install software-properties-common
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    add-apt-repository -y ppa:chris-lea/redis-server
    apt update
    apt -y install php7.2 php7.2-cli php7.2-gd php7.2-mysql php7.2-pdo php7.2-mbstring php7.2-tokenizer php7.2-bcmath php7.2-xml php7.2-fpm php7.2-curl php7.2-zip nginx curl tar unzip git redis-server
}
