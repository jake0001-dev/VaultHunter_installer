#/bin/bash

# This script auto deploy a VaultHunter server
# It will install all the required packages and configure the server

# Check if the script is run as sudo user
if [ "$EUID" -ne 0 ]
  then echo "Please run as a sudo user NOT as root"
  exit
fi

# Get username of user running the script
username=$(logname)

if [ username == "root" ]; then
    echo "Please run as a non-root user"
    exit
fi

# Check if the script is run on a Debian based system

if [ ! -f /etc/debian_version ]; then
    echo "This script is only for Debian based systems"
    exit
fi



## Check if Java version 17 is installed

if ! java -version 2>&1 | grep -q "17"
then
    echo "Java version 17 is required"

    # Install Java 17
    sudo apt install openjdk-17-jdk openjdk-17-jre

    # Check if Java version 17 is installed
    if ! java -version 2>&1 | grep -q "17"
    then
        echo "Java version 17 could not be installed"
        exit
    fi
fi

## Install required packages
apt update
apt install -y git screen
apt install unzip
## Install VaultHunter
mkdir /home/${username}/vaulthunter
cd /home/${username}/vaulthunter
wget -O Vault_hunter.zip https://mediafilez.forgecdn.net/files/4516/817/Vault+Hunters+3rd+Edition-Update-9.0.3_Server-Files.zip
## Fetch Forge installer
wget -O forge-installer.jar https://maven.minecraftforge.net/net/minecraftforge/forge/1.18.2-40.2.0/forge-1.18.2-40.2.0-installer.jar
## Install Forge
java -jar forge-installer.jar --installServer
unzip Vault_hunter.zip
rm Vault_hunter.zip
rm forge-installer.jar

## Create start script
echo "java @user_jvm_args.txt @libraries/net/minecraftforge/forge/1.18.2-40.2.0/unix_args.txt "$@"" > run.sh

## Create eula.txt
echo "eula=true" > eula.txt


## Create systemd service
echo "[Unit]
Description=VaultHunter Server
After=network.target

[Service]
Type=simple
User=${username}
WorkingDirectory=/home/${username}/vaulthunter
ExecStart=/bin/bash /home/${username}/vaulthunter/run.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/vaulthunter.service


## Start VaultHunter
systemctl daemon-reload
systemctl enable vaulthunter
systemctl start vaulthunter

## Finish message
echo "VaultHunter server installed"
echo "The server will start in a few seconds"
echo "You can connect to the server with the following IP address:"
echo "$(hostname -I):25565"