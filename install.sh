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
