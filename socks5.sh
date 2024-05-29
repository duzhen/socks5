#!/bin/bash

echo -e "Please enter the username for the socks5 proxy:"
read username
echo -e "Please enter the password for the socks5 proxy:"
read -s password

# Update repositories
sudo apt update -y

# Install dante-server
sudo apt install dig ufw iptables dante-server -y

# Get ETH and IP
ETH=$(ip -o -4 route show to default | awk '{print $5}')
IP=$(dig +short stos.ddns.net | head -n1)

# Create the configuration file
sudo echo -e "logoutput: /var/log/danted.log
internal: $ETH port = 1080
external: $ETH
method: none
user.privileged: root
user.notprivileged: nobody
client pass {
    from: $IP/32 to: 0.0.0.0/0
    log: connect disconnect error
}
socks pass {
    from: $IP/32 to: 0.0.0.0/0
    log: connect disconnect error
}" > /etc/danted.conf

# Add user with password
#sudo useradd --shell /usr/sbin/nologin $username
#echo "$username:$password" | sudo chpasswd

# Check if UFW is active and open port 1080 if needed
if sudo ufw status | grep -q "Status: active"; then
    sudo ufw allow 1080/tcp
fi

# Check if iptables is active and open port 1080 if needed
if sudo iptables -L | grep -q "ACCEPT     tcp  --  anywhere             anywhere             tcp dpt:1080"; then
    echo "Port 1080 is already open in iptables."
else
    sudo iptables -A INPUT -p tcp --dport 1080 -j ACCEPT
fi

# Restart dante-server
sudo systemctl restart danted

# Enable dante-server to start at boot
sudo systemctl enable danted
