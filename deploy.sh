#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
iptables -F && iptables -X && iptables -t nat -F && iptables -t nat -X && iptables -t mangle -F && iptables -t mangle -X && iptables -t raw -F && iptables -t raw -X && iptables -t security -F && iptables -t security -X && iptables -P INPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables -P OUTPUT ACCEPT
apt update -y
dpkg --force-all --configure -a
apt install -y wget nano screen
#apt-get install -y iptables redsocks curl wget lynx
apt-get install -y iptables curl wget lynx

systemctl start docker
systemctl enable docker

while ! systemctl is-active --quiet docker; do
    echo "En attente du démarrage de Docker..."
    sleep 2
done

echo "Docker est maintenant actif."

if systemctl is-active --quiet docker; then
    echo "Arrêt et suppression du conteneur 9hits..."
    docker stop 9hits > /dev/null 2>&1
    docker rm 9hits > /dev/null 2>&1
    echo "Conteneur 9hits arrêté et supprimé."
else
    echo "Docker n'est pas actif. Impossible d'arrêter ou de supprimer le conteneur 9hits."
fi

echo "Désinstallation de screen..."
apt remove --purge -y screen

rm -rf /var/run/screen/*
rm -rf /run/screen/*
rm -rf /tmp/screens/*

echo "Réinstallation de screen..."
apt install -y screen

if command -v screen &> /dev/null; then
    echo "Screen a été réinstallé avec succès."
else
    echo "Erreur : Screen n'a pas pu être réinstallé."
    exit 1
fi

pkill -f tor
screen -ls | grep -oP '\d+\.\w+' | while read session_id; do
    screen -X -S "$session_id" quit
done

sed -i 's/\r$//' /home/runner/start.sh
chmod +x /home/runner/start.sh
#screen -dmS tor_proxies bash -c '/home/runner/start.sh 15; exec bash'

#echo "Vérification que le port 10000 est utilisé..."
#while ! ss -tuln | grep -q ':10000\b'; do
#    echo "Le port 10000 n'est pas encore utilisé. Attente de 5 secondes..."
#    sleep 5
#done
#echo "Le port 10000 est maintenant utilisé."

#sleep 120

#mv /home/runner/redsocks.conf /etc/redsocks.conf
#/etc/init.d/redsocks restart

#for port in {10000..10014}; do
#    iptables -t nat -A OUTPUT -p tcp --dport $port -j RETURN
#    echo "Règle ajoutée pour le port $port"
#done
#iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-port 12345
#iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-port 12345

max_attempts=100
attempt=1

while [ $attempt -le $max_attempts ]; do
    echo "Tentative de création $attempt/$max_attempts du conteneur 9hits..."

    #docker run -d --network=host --name=9hits 9hitste/appv5 /nh.sh --token=e0ebc71df2b7f3fd4684aa26ba99ffcc --download-url="https://www.dropbox.com/scl/fi/1ns7i1z1lg6unizc7bxbp/9hitsv5-linux64.tar-2.bz2?rlkey=w6ybk03qqkb5jgg60c4p3seym&st=nimrhfu9&dl=1" --system-session --bulk-add-proxy-type=socks5 --bulk-add-proxy-list="localhost:10000|localhost:10001|localhost:10002|localhost:10003|localhost:10004|localhost:10005|localhost:10006|localhost:10007|localhost:10008|localhost:10009|localhost:10010|localhost:10011|localhost:10012|localhost:10013|localhost:10014" --allow-crypto=no --session-note=my-ssh --note=my-vps1 --hide-browser
    #docker run -d --network=host --name=9hits 9hitste/appv5 /nh.sh --token=e0ebc71df2b7f3fd4684aa26ba99ffcc --system-session --ex-proxy-sessions=15 --ex-proxy-url=http://proxy.9hits.com/pool/c47c92ab852972abd1439bc9b7bd239a --allow-crypto=no --session-note=http-pool --note=my-vps --hide-browser
    docker run -d --network=host --name=9hits 9hitste/app /nh.sh --token=e0ebc71df2b7f3fd4684aa26ba99ffcc --download-url="https://www.dropbox.com/scl/fi/xp4o2uc0ai154eh7s3op6/9hitsv3-linux64.tar.bz2?rlkey=grr63ncpub69j6a3p1m4k1v7p&e=2&st=f99ljjib&dl=1" --system-session --ex-proxy-sessions=15 --ex-proxy-url=http://proxy.9hits.com/pool/c47c92ab852972abd1439bc9b7bd239a --allow-crypto=no --session-note=http-pool --note=my-vps --hide-browser

    if docker ps --format '{{.Names}}' | grep -q '^9hits$'; then
        echo "Le conteneur 9hits a été créé avec succès."
        break
    else
        docker stop 9hits > /dev/null 2>&1
        docker rm 9hits > /dev/null 2>&1
        echo "Échec de la création du conteneur 9hits. Réessai dans 5 secondes..."
        sleep 5
        attempt=$((attempt + 1))
    fi
done

if [ $attempt -gt $max_attempts ]; then
    echo "Échec de la création du conteneur 9hits après $max_attempts tentatives."
    exit 1
fi

max_attempts=100
attempt=1

while [ $attempt -le $max_attempts ]; do
    echo "Tentative de démarrage $attempt/$max_attempts..."
    docker start 9hits

    if docker ps --format '{{.Names}}' | grep -q '^9hits$'; then
        echo "Le conteneur 9hits a été démarré avec succès."
        break
    else
        echo "Échec du démarrage du conteneur 9hits. Réessai dans 5 secondes..."
        sleep 5
        attempt=$((attempt + 1))
    fi
done

if [ $attempt -gt $max_attempts ]; then
    echo "Échec du démarrage du conteneur 9hits après $max_attempts tentatives."
fi