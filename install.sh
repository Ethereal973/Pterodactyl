server_setup() {
    output "Hope you enjoy this install script. https://thientran.io"
    read -p "Enter admin email (e.g. admin@example.com) : " EMAIL
    read -p "Enter servername (e.g. portal.example.com) : " SERVERNAME
    read -p "Enter time zone (e.g. America/New_York) : " TIME
    read -p "Password : " PASS
}

initial() {
    echo "Updating your server!"
    sudo apt-get -y update 
    sudo apt-get -y upgrade
    sudo apt-get -y autoremove
    sudo apt-get -y autoclean
}
