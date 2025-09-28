#!/bin/bash

# ASCII Art
ascii_art="

      .___  .__                                  _____                            .__          ._.
|   | |  |   _______  __ ____    __ __    /  _  \ _____  ___.__.__ __  _____|  |__ _____ | |
|   | |  |  /  _ \  \/ // __ \  |  |  \  /  /_\  \\__  \<   |  |  |  \/  ___/  |  \\__  \| |
|   | |  |_(  <_> )   /\  ___/  |  |  / /    |    \/ __ \\___  |  |  /\___ \|   Y  \/ __ \\|
|___| |____/\____/ \_/  \___  > |____/  \____|__  (____  / ____|____//____  >___|  (____  /_
                            \/                  \/     \/\/               \/     \/     \/\

                                 
"

echo "i love u aayusha!"
 
# Install puffer panel
apt update
apt install sudo
apt install systemctl
curl -s https://packagecloud.io/install/repositories/pufferpanel/pufferpanel/script.deb.sh?any=true | sudo bash
sudo apt update
sudo apt-get install pufferpanel
