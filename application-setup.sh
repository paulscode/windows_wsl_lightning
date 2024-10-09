#!/bin/bash

# Check if the script is run as root and exit if true
if [ "$EUID" -eq 0 ]; then
    echo "This script should not be run with 'sudo'. Please run it as a regular user."
    exit 1
fi

# Check if $HOME/.lightning/commando.config exists, exit if not
if [ ! -f "$HOME/.lightning/commando.config" ]; then
    echo "You must run lightning-setup.sh first."
    exit 1
fi

# Check if $HOME/.lightning/config.json exists, exit if true
if [ -f "$HOME/.lightning/config.json" ]; then
    echo "This script can only be run once."
    exit 1
fi

# Check if the lightningd process is running
if ! pgrep -x "lightningd" > /dev/null; then
    echo "Please run lightningd first, and check the log for errors before running this script."
    exit 1
fi

# Navigate to the home directory
cd "$HOME"

# Extract LIGHTNING_PUBKEY using lightning-cli
LIGHTNING_PUBKEY=$(lightning-cli getinfo | grep -oP '(?<="id": ")[^"]+')
if [ -z "$LIGHTNING_PUBKEY" ]; then
    echo "Failed to retrieve the lightning public key. Make sure lightningd is running correctly."
    exit 1
fi

# Extract LIGHTNING_RUNE using lightning-cli
LIGHTNING_RUNE=$(lightning-cli commando-rune)
if [ -z "$LIGHTNING_RUNE" ]; then
    echo "Failed to retrieve the lightning rune. Make sure lightningd is running correctly."
    exit 1
fi

# Configure Commando:
cat <<EOF1 > "$HOME/.lightning/commando.config"
LIGHTNING_PUBKEY="$LIGHTNING_PUBKEY"
LIGHTNING_RUNE="$LIGHTNING_RUNE"
EOF1

# Ensure no newline at the end of the file
truncate -s -1 "$HOME/.lightning/commando.config"

# Create default configuration for cln-application
touch "$HOME/.lightning/config.json"
chmod 600 "$HOME/.lightning/config.json"
cat <<EOF2 > "$HOME/.lightning/config.json"
{
  "unit": "SATS",
  "fiatUnit": "USD",
  "appMode": "DARK",
  "isLoading": false,
  "error": null,
  "singleSignOn": false,
  "password": ""
}
EOF2

# Make sure Nodejs is installed
sudo apt-get install -y nodejs

# Download and install cln-application
wget https://github.com/ElementsProject/cln-application/archive/refs/tags/v0.0.6.tar.gz -O cln-application-v0.0.6.tar.gz
tar -xzf cln-application-v0.0.6.tar.gz
rm -f cln-application-v0.0.6.tar.gz
mv cln-application-0.0.6 cln-application
cd cln-application
npm install --omit=dev
npm audit fix

# Return to the home directory
cd "$HOME"

echo "CLN Application setup complete. Please reboot and ensure Bitcoin Core is running before proceeding."
