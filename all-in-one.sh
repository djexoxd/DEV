#!/bin/bash

# Colors and styles
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
BLUE="\e[34m"
BOLD="\e[1m"
RESET="\e[0m"

function pause() {
    read -rp "Press Enter to continue..."
}

function header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo " .___  .__                                  _____                            .__          ._."
    echo " |   | |  |   _______  __ ____    __ __    /  _  \ _____  ___.__.__ __  _____|  |__ _____ | |"
    echo " |   | |  |  /  _ \  \/ // __ \  |  |  \  /  /_\  \\__  \<   |  |  |  \/  ___/  |  \\__  \| |"
    echo " |   | |  |_(  <_> )   /\  ___/  |  |  / /    |    \/ __ \\___  |  |  /\___ \|   Y  \/ __ \\|"
    echo " |___| |____/\____/ \_/  \___  > |____/  \____|__  (____  / ____|____//____  >___|  (____  /_"
    echo "                             \/                  \/     \/     \/\/               \/     \/     \/\/  -"
    echo "======================================"
    echo "       Game Panel Installer"
    echo "======================================"
    echo -e "${RESET}"
}

function install_pufferpanel() {
    header
    echo -e "${YELLOW}Installing PufferPanel (Docker)...${RESET}"
    sudo su -c "
        apt update && apt upgrade -y &&
        mkdir -p /var/lib/pufferpanel &&
        docker volume create pufferpanel-config &&
        docker create --name pufferpanel \
            -p 8080:8080 -p 5657:5657 \
            -v pufferpanel-config:/etc/pufferpanel \
            -v /var/lib/pufferpanel:/var/lib/pufferpanel \
            -v /var/run/docker.sock:/var/run/docker.sock \
            --restart=on-failure \
            pufferpanel/pufferpanel:latest &&
        docker start pufferpanel
    "
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}PufferPanel installed and container started.${RESET}"
        echo -e "Now add a user:"
        sudo docker exec -it pufferpanel /pufferpanel/pufferpanel user add
    else
        echo -e "${RED}Something went wrong while installing PufferPanel. Check the output above.${RESET}"
    fi
    pause
}

function install_pufferpanel_v3() {
    header
    echo -e "${YELLOW}Installing PufferPanel V3...${RESET}"
    echo -e "Running installation script from the official source..."
    # Replace with actual commands if you have them, example:
    sudo su -c "
        bash <(curl -s https://example.com/pufferpanel-v3-install.sh)
    "
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}PufferPanel V3 installation complete.${RESET}"
    else
        echo -e "${RED}PufferPanel V3 installation failed or the URL is a placeholder. Update the URL if needed.${RESET}"
    fi
    pause
}

function install_skyport_panel() {
    header
    echo -e "${YELLOW}Installing Skyport Panel...${RESET}"
    sudo su -c "bash <(curl -s https://raw.githubusercontent.com/JishnuTheGamer/skyport/refs/heads/main/panel)"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Skyport Panel installed.${RESET}"
    else
        echo -e "${RED}Skyport Panel installation failed. Check your network and the repository URL.${RESET}"
    fi
    pause
}

function install_skyport_wings() {
    header
    echo -e "${YELLOW}Installing Skyport Wings (Node)...${RESET}"
    sudo su -c "bash <(curl -s https://raw.githubusercontent.com/JishnuTheGamer/skyport/refs/heads/main/wings)"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Skyport Wings bootstrap script ran.${RESET}"
    else
        echo -e "${RED}Skyport Wings installation script failed. Check the repository URL or network.${RESET}"
    fi
    echo -e "Navigate to 'skyportd' directory and configure your node:"
    echo -e "${CYAN}cd skyportd${RESET}"
    echo -e "Then start with pm2:"
    echo -e "${CYAN}pm2 start .${RESET}"
    pause
}

function install_hydra_dash_panel() {
    header
    echo -e "${YELLOW}Installing Hydra Dash (Panel)...${RESET}"
    echo -e "Running panel install script from repository..."
    sudo su -c "bash <( curl -s https://raw.githubusercontent.com/JishnuTheGamer/dashboard/refs/heads/main/dash )"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Hydra Dash panel install script executed.${RESET}"
    else
        echo -e "${RED}Hydra Dash panel installation failed. Verify the URL and network connectivity.${RESET}"
    fi
    pause
}

function install_hydra_dash_node() {
    header
    echo -e "${YELLOW}Installing Hydra Dash Node (HydraDAEMON)...${RESET}"
    sudo su -c "
        set -e
        cd /opt || mkdir -p /opt && cd /opt
        if [ -d HydraDAEMON ]; then
            echo 'HydraDAEMON directory already exists in /opt, pulling latest changes...'
            cd HydraDAEMON && git pull || true
        else
            git clone https://github.com/hydren-dev/HydraDAEMON
            cd HydraDAEMON
        fi
        npm install
    "
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}HydraDAEMON cloned and dependencies installed.${RESET}"
        echo -e "${CYAN}Next steps:${RESET}"
        echo -e "1) Edit the node configuration file (follow the project's README) and paste your configuration."
        echo -e "   Example: ${CYAN}nano /opt/HydraDAEMON/config.json${RESET}"
        echo -e "2) Start the node:"
        echo -e "   ${CYAN}cd /opt/HydraDAEMON && node .${RESET}"
        echo -e "   (Consider using pm2 or a systemd service for production.)"
    else
        echo -e "${RED}Failed to clone or install HydraDAEMON. Check git/npm output above.${RESET}"
    fi
    pause
}

function install_hydra_dash() {
    while true; do
        header
        echo -e "${BOLD}Hydra Dash - select an option:${RESET}"
        echo -e "${BLUE}1)${RESET} Panel install (automatic) - runs dashboard install script"
        echo -e "${BLUE}2)${RESET} Node install (HydraDAEMON) - clone & npm install"
        echo -e "${BLUE}3)${RESET} Back to main menu"
        echo
        read -rp "Enter your choice [1-3]: " hchoice
        case $hchoice in
            1) install_hydra_dash_panel ;;
            2) install_hydra_dash_node ;;
            3) return ;;
            *) echo -e "${RED}Invalid option! Please enter a number between 1 and 3.${RESET}" ; pause ;;
        esac
    done
}

function menu() {
    while true; do
        header
        echo -e "${BOLD}Select an option to install:${RESET}"
        echo -e "${BLUE}1)${RESET} PufferPanel (Docker)"
        echo -e "${BLUE}2)${RESET} PufferPanel V3"
        echo -e "${BLUE}3)${RESET} Skyport Panel"
        echo -e "${BLUE}4)${RESET} Skyport Wings (Node)"
        echo -e "${BLUE}5)${RESET} Hydra Dash"
        echo -e "${BLUE}6)${RESET} Exit"
        echo
        read -rp "Enter your choice [1-6]: " choice
        case $choice in
            1) install_pufferpanel ;;
            2) install_pufferpanel_v3 ;;
            3) install_skyport_panel ;;
            4) install_skyport_wings ;;
            5) install_hydra_dash ;;
            6) echo -e "${GREEN}Exiting installer. Goodbye!${RESET}"; exit 0 ;;
            *) echo -e "${RED}Invalid option! Please enter a number between 1 and 6.${RESET}" ; pause ;;
        esac
    done
}

menu
