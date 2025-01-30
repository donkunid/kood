#!/bin/bash

# Fonction de journalisation
function log() {
    if [[ $# == 1 ]]; then
        level="info"
        msg=$1
    elif [[ $# == 2 ]]; then
        level=$1
        msg=$2
    fi
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") [controller] [${level}] ${msg}"
}

# Vérification des arguments
if [[ $# -ne 1 ]]; then
    log "fatal" "Usage: $0 <number_of_tor_instances>"
    exit 1
fi

TOR_INSTANCES=$1

if ((TOR_INSTANCES < 1 || TOR_INSTANCES > 40)); then
    log "fatal" "The number of Tor instances has to be within the range of 1...40"
    exit 1
fi

# Installation de Tor
log "Installing Tor..."
apt-get update && apt-get install -y tor

# Configuration de Tor
log "Configuring Tor..."
cat <<EOF > /etc/tor/torrc.default
Log notice stdout
HashedControlPassword 16:0E845EB82BCDB7BF604C82C0D8A5E4A4D44EDB7360098EBE6B099505D3
RunAsDaemon 0
User tor
NewCircuitPeriod 30
MaxCircuitDirtiness 300
UseEntryGuards 0
LearnCircuitBuildTimeout 1
ExitRelay 0
RefuseUnknownExits 0
ClientOnly 1
EOF

rm -rf /etc/tor/torrc.sample

# Création des répertoires nécessaires
mkdir -p /var/local/tor
chown -R tor: /var/local/tor

# Démarrage des instances Tor
base_tor_socks_port=10000

log "Starting a pool of ${TOR_INSTANCES} Tor instances..."

for ((i = 0; i < TOR_INSTANCES; i++)); do
    socks_port=$((base_tor_socks_port + i))
    tor_data_dir="/var/local/tor/${i}"
    mkdir -p "${tor_data_dir}" && chmod -R 700 "${tor_data_dir}" && chown -R tor: "${tor_data_dir}"
    (tor --PidFile "${tor_data_dir}/tor.pid" \
      --SocksPort 127.0.0.1:"${socks_port}" \
      --dataDirectory "${tor_data_dir}" 2>&1 |
      sed -r "s/^(\w+\ [0-9 :\.]+)(\[.*)[\r\n]?$/$(date -u +"%Y-%m-%dT%H:%M:%SZ") [tor#${i}] \2/") &
    log "Started Tor instance #${i} with SOCKS port ${socks_port}"
done

# Boucle infinie pour maintenir le script en vie
log "All Tor instances are running. Press Ctrl+C to stop."
while :; do
    sleep 60
done