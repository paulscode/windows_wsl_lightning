# Windows WSL Lightning

This project contains a couple of utilities to simplify setting up Core Lightning on Windows via WSL.

# IMPORTANT NOTES (Read before proceeding)

Bitcoin Knots (or Bitcoin Core) must be installed in Windows, configured as a full (unpruned) node, and have completed the IBD sync process.
These scripts assume the default installation folder was used (C:\Program Files\Bitcoin).  If this is not where you have installed the application, then DO NOT PROCEED!

# The Process

## STEP 1: Enable Virtualization
- Reboot your computer
- During startup, press whatever hotkey brings you into the Bios settings (this is specific to your computer model)
- In the Bios, locate and enable the option called something like "Virtualization" (examples: "Intel Virtual Technology", "AMT Virtualization")
- Restart Windows
- In the task bar, search for "Turn Windows features on or off"
- Locate and Enable "Virtual Machine Platform"
## STEP 2: Install WSL (Ubuntu)
- In the task bar, search for "Windows PowerShell"
- Right-click and select "Run as Administrator"
- Type in:
  ```bash
  wsl --install
  ```
- Close Windows PowerShell and Reboot
## STEP 3: Look up IP Addresses for WSL (Ubuntu) and Windows
- In the task bar, search for and launch the "Ubuntu" app
- Enter a username and password when prompted (may be different than your Windows username and password)
- Wait for the command prompt to finish loading
- Execute the following command, and wite down the results as "WSL IP Address":
  ```bash
  hostname -I | awk '{print $1}'
  ```
- Execute the following command, and write this one down as "Windows IP Address":
  ```bash
  grep nameserver /etc/resolv.conf | awk '{print $2}'
  ```
## STEP 4: Configure firewall rule for WSL to communicate with Windows
- In the task bar, search for and launch "Windows Defender Firewall"
- Click on "Advanced Settings"
- Click on "Inbound Rules"
- Click on "New Rule"
- Select "Port", and click "Next"
- Select "TCP"
- Select Specific Local Port, enter "8332", and click "Next"
- Select "Allow the Connection", and click "Next"
- Leave the "Domain", "Private", and "Public" checkboxes checked, and click "Next"
- For Name, enter "Bitcoin RPC"
- For Description, enter "Allow WSL to communicate with you Bitcoin node", and click "Finish"
- Right-click the new "Bitcoin RPC", and select "Properties"
- Click Scope
- For Local IP Addresses, select "These IP Addresses" and click "Add"
- Enter "172.0.0.0/8" and click "OK"
- For Remote IP Addresses, select "These IP Addresses" and click "Add"
- Enter "172.0.0.0/8" and click "OK"
- Click "Apply" then "OK", and close Windows Defender Firewall
## STEP 5: Configure Bitcoin node to accept RPC
- Launch Bitcoin Knots (or Bitcoin Core)
- Click on "Settings", select "Options", and enable the "RPC Server" checkbox
- Click "Open Configuration File", and click "Continue"
- Enter the following (change "someusername" and "psw0rd!", and remember for STEP 6 what you chose):
  ```ini
  server=1
  rpcuser=someusername
  rpcpassword=psw0rd!
  rpcbind=0.0.0.0
  rpcallowip=172.0.0.0/8
  rpcport=8332
  ```
- Select "File", then "Save", and close the editor
- Click "OK"
## STEP 6: Setup lightningd (in WSL)
- Return to the WSL command prompt (should still be open from STEP 3)
- Enter the following commands:
  ```bash
  cd ~
  wget https://raw.githubusercontent.com/paulscode/windows_wsl_lightning/refs/heads/main/lightning-setup.sh
  chmod 700 lightning-setup.sh
  ./lightning-setup.sh
  ```
- You will be propted to enter a few values to configure your lightning node (the "RPC username" and "RPC password" are from STEP 5)
- Wait for script to finish executing, then enter:
  ```bash
  rm -f lightning-setup.sh
  sudo reboot
  ```
- Close Bitcoin Knots (or Bitcoin Core) and wait for it to completely shut down
- Reboot the computer
## STEP 7: Setup CLN Application
- Launch Bitcoin Knots (or Bitcoin Core) and wait for it to connect to some peers
- In the task bar, search for and launch the "Ubuntu" app
- Wait for the command prompt to finish loading
- Enter the following command:
  ```bash
  lightningd
  ```
- If errors appear, STOP HERE AND DO NOT PROCEED!
- Wait for a few seconds, then enter the following command:
  ```bash
  cat .lightning/log
  ```
- If any errors appear (such as modules missing), STOP HERE AND DO NOT PROCEED!
- If there are no errors in the log, enter the following commands:
  ```bash
  wget https://raw.githubusercontent.com/paulscode/windows_wsl_lightning/refs/heads/main/application-setup.sh
  chmod 700 application-setup.sh
  ./application-setup.sh
  ```
- Wait for script to finish executing, then enter:
  ```bash
  rm -f application-setup.sh
  sudo reboot
  ```
- Close Bitcoin Knots (or Bitcoin Core) and wait for it to completely shut down
- Reboot the computer
## STEP 8: Enjoy!
- Launch Bitcoin Knots (or Bitcoin Core) and wait for it to connect to some peers
- In the task bar, search for and launch the "Ubuntu" app
- Wait for the command prompt to finish loading
- Enter the following command:
  ```bash
  lightningd
  ```
- Wait for a few seconds, then enter the following command:
  ```bash
  cln-application
  ```
- Copy the URL (should look something like http://172.30.225.200:8080, but the IP will likely be different)
- Open a browser in Windows, and enter the URL

# Shutting Down
- Close the Browser
- Return to the WSL command prompt, and press Ctrl+c to stop the CLN Application
- Enter the following command:
  ```bash
  sudo reboot
  ```
- Close Bitcoin Knots (or Bitcoin Core) and wait for it to completely shut down
- Reboot the computer before attempting to launch again
