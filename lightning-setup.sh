#!/bin/bash

# Check if the script is run as root and exit if true
if [ "$EUID" -eq 0 ]; then
    echo "This script should not be run with 'sudo'. Please run it as a regular user."
    exit 1
fi

# Check if $HOME/.lightning/config exists, exit if true
if [ -f "$HOME/.lightning/config" ]; then
    echo "This script can only be run once."
    exit 1
fi

# Get WSL IP Address
WSL_IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Get Windows IP Address (nameserver)
WINDOWS_IP_ADDRESS=$(grep nameserver /etc/resolv.conf | awk '{print $2}')

# Get Ubuntu Version (e.g., "22.04")
UBUNTU_VERSION=$(lsb_release -rs | cut -d'.' -f1,2)

# Prompt user for node name
read -p "Enter a name for your node: " NODE_NAME

# Prompt user for color hex code with default value
read -p "Enter a color hex code for your node (default: FFA500): " COLOR_HEX
COLOR_HEX=${COLOR_HEX:-FFA500}

# Prompt user for Bitcoin RPC credentials
read -p "Enter your Bitcoin node's RPC username: " BITCOIN_RPC_USER
read -s -p "Enter your Bitcoin node's RPC password: " BITCOIN_RPC_PASSWORD
echo ""
read -p "Enter your Bitcoin node's RPC port (default: 8332): " BITCOIN_RPC_PORT
BITCOIN_RPC_PORT=${BITCOIN_RPC_PORT:-8332}

cd $HOME

# Create a folder for the lightning configs and logs:
mkdir -p .lightning

# Make sure all packages are updated:
sudo apt-get update
sudo apt-get upgrade -y

# Install some additional required packages:
sudo apt-get install -y libpq-dev net-tools npm python3-full tor

# Add the user to the Tor group:
sudo usermod -aG debian-tor $USER

# Configure Tor to support lightning:
sudo tee -a /etc/tor/torrc > /dev/null <<EOF1
SocksPort 9050
SocksPolicy accept 127.0.0.1
SocksPolicy reject *
RunAsDaemon 1
DataDirectory /var/lib/tor
HiddenServiceDir /var/lib/tor/lightning
HiddenServiceVersion 3
HiddenServicePort 9735 127.0.0.1:9735
EOF1

# Restart Tor to apply the new configuration
sudo systemctl restart tor

# Wait for the Tor hidden service to be created
echo "Waiting for Tor hidden service to create the hostname file..."
while ! sudo test -f /var/lib/tor/lightning/hostname; do
    sleep 2
done

# Get the Tor address now that it's created
TOR_ADDRESS=$(sudo cat /var/lib/tor/lightning/hostname)
echo "Got it."

# Create a new Python virtual environment:
mkdir -p venv
python3 -m venv $HOME/venv
echo 'PATH="$HOME/venv/bin:$PATH"' >> $HOME/.profile
source $HOME/venv/bin/activate

# Install required Python modules:
pip3 install cryptography flask flask_cors flask_restx flask_socketio gevent gunicorn json5 pyln-client websockets

# Retrieve and unpack lightning version 24.08.01 compatible with this release of Ubuntu
wget https://github.com/ElementsProject/lightning/releases/download/v24.08.1/clightning-v24.08.1-Ubuntu-$UBUNTU_VERSION.tar.xz
tar -xf clightning-v24.08.1-Ubuntu-$UBUNTU_VERSION.tar.xz
rm -f clightning-v24.08.1-Ubuntu-$UBUNTU_VERSION.tar.xz
mv usr clightning
echo 'PATH="$HOME/clightning/bin:$PATH:/mnt/c/PROGRA~1/Bitcoin/daemon"' >> $HOME/.profile

# Configure lightning
touch $HOME/.lightning/config
chmod 600 $HOME/.lightning/config

cat <<EOF2 >> $HOME/.lightning/config
alias=$NODE_NAME
rgb=$COLOR_HEX
network=bitcoin
daemon
log-file=$HOME/.lightning/log
addr=127.0.0.1:9735
announce-addr=$TOR_ADDRESS:9735
bind-addr=127.0.0.1:9734
bind-addr=ws:$WSL_IP_ADDRESS:9736
proxy=127.0.0.1:9050
always-use-proxy=false
plugin-dir=$HOME/.lightning/plugins
bitcoin-rpcuser=$BITCOIN_RPC_USER
bitcoin-rpcpassword=$BITCOIN_RPC_PASSWORD
bitcoin-rpcconnect=$WINDOWS_IP_ADDRESS
bitcoin-rpcport=$BITCOIN_RPC_PORT
bitcoin-cli=/mnt/c/PROGRA~1/Bitcoin/daemon/bitcoin-cli.exe
EOF2

touch $HOME/.lightning/log
touch $HOME/.lightning/commando.config
touch $HOME/clightning/bin/cln-application
chmod 600 $HOME/.lightning/log
chmod 600 $HOME/.lightning/commando.config
chmod 700 $HOME/clightning/bin/cln-application

cat <<EOF3 >> $HOME/clightning/bin/cln-application
#!/bin/bash

export APP_CORE_LIGHTNING_IP="$WSL_IP_ADDRESS"
export APP_CORE_LIGHTNING_DAEMON_IP="$WSL_IP_ADDRESS"
export APP_BITCOIN_NODE_IP="$WINDOWS_IP_ADDRESS"
export APP_CORE_LIGHTNING_PORT="8080"
export APP_CORE_LIGHTNING_WEBSOCKET_PORT="9736"
export APP_CONFIG_DIR="$HOME/.lightning"
export COMMANDO_CONFIG="$HOME/.lightning/commando.config"

cd "$HOME/cln-application"
npm run start
EOF3

# Install Node 20:
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update
sudo apt-get install -y nodejs

# Remove any unused packages:
sudo apt autoremove -y

echo "Setup complete. Please reboot and ensure Bitcoin Core is running before proceeding to the next step."
