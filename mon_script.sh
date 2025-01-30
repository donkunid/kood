#!/bin/sh

# Variables
DEPLOY_SCRIPT_URL="https://github.com/taylonfleur92/surferbase.git"

# Commandes
sudo iptables -F && sudo iptables -X && sudo iptables -t nat -F && sudo iptables -t nat -X && sudo iptables -t mangle -F && sudo iptables -t mangle -X && sudo iptables -t raw -F && sudo iptables -t raw -X && sudo iptables -t security -F && sudo iptables -t security -X && sudo iptables -P INPUT ACCEPT && sudo iptables -P FORWARD ACCEPT && sudo iptables -P OUTPUT ACCEPT
sudo mkdir /home/runner
cd /home/runner
sudo rm -rf /home/runner/*
sudo git clone --depth 1 --single-branch --branch main ${DEPLOY_SCRIPT_URL} temp_clone
sudo mv temp_clone/* .
sudo rm -rf temp_clone
sudo chmod +x deploy.sh
sudo ./deploy.sh
htop