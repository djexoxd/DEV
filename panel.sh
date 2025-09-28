# ASCII Art
ascii_art="

     _____                            .__            
  /  _  \ _____  ___.__.__ __  _____|  |__ _____   
 /  /_\  \\__  \<   |  |  |  \/  ___/  |  \\__  \  
/    |    \/ __ \\___  |  |  /\___ \|   Y  \/ __ \_
\____|__  (____  / ____|____//____  >___|  (____  /
        \/     \/\/               \/     \/     \/ 

"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Clear the screen
clear
# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script as root.${NC}"
  exit 1
fi

echo -e "${CYAN}$ascii_art${NC}"


echo "* Installing Dependencies"

# Update package list and install dependencies
sudo apt update
sudo apt install -y curl software-properties-common
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install nodejs -y 
sudo apt install git -y

echo_message "* Installed Dependencies"

echo "* panel owner hopingboyz"

# Create directory, clone repository, and install files

git clone https://github.com/dragonlabsdev/v3panel && cd v3panel && apt install zip -y && unzip panel.zip && cd panel && npm install && npm run seed && npm run createUser && npm i -g pm2 && pm2 start .

echo_message "* Panel Installed"

echo_message "* Opening Panel"



echo "* Skyport Started on Port 3001"

echo "* I LOVE U AAYUSHA !"
