#!/bin/bash

# Print ASCII Art
echo " -.___  .__                                  _____                            .__          ._."
echo "|   | |  |   _______  __ ____    __ __    /  _  \ _____  ___.__.__ __  _____|  |__ _____ | |"
echo "|   | |  |  /  _ \  \/ // __ \  |  |  \  /  /_\  \\__  \<   |  |  |  \/  ___/  |  \\__  \| |"
echo "|   | |  |_(  <_> )   /\  ___/  |  |  / /    |    \/ __ \\___  |  |  /\___ \|   Y  \/ __ \\|"
echo "|___| |____/\____/ \_/  \___  > |____/  \____|__  (____  / ____|____//____  >___|  (____  /_"
echo "                            \/                  \/     \/\/               \/     \/     \/\/"

# Message
echo ""
echo "I love her!!"
echo "pufferpanel insall !"

# Update packages
sudo apt update -y

# Install required packages
sudo apt install -y curl sudo gnupg

# Add the PufferPanel APT repository
curl -s https://packagecloud.io/install/repositories/pufferpanel/pufferpanel/script.deb.sh | sudo bash

# Update again after adding new repo
sudo apt update -y

# Install PufferPanel
sudo apt install -y pufferpanel

# Add a user for PufferPanel (interactive setup)
sudo pufferpanel user add

# Enable and start the PufferPanel service
sudo systemctl enable --now pufferpanel
