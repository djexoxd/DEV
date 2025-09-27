#!/bin/bash

# ASCII Header
echo -e "\n\033[36m\033[1m
   _____                            .__              ____  __.   _________  
  /  _  \\ _____  ___.__.__ __  _____|  |__ _____    |    |/ _|   \\_   ___ \\ 
 /  /_\\  \\\\__  <\\   |  |  |  \\/  ___/  |  \\\\__  \\   |      <     /    \\  \\/ 
/    |    \\/ __ \\\\___  |  |  /\\___ \\|   Y  \\/ __ \\_ |    |  \\    \\     \\____
\\____|__  (____  / ____|____//____  >___|  (____  / |____|__ \\ /\\ \\______  /
        \\/     \\/\\/               \\/     \\/     \\/          \\/ \\/        \\/  
\033[0m\n"

# Colors and styles
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
BLUE="\e[34m"
RESET="\e[0m"
BOLD="\e[1m"
ITALIC="\e[3m"
BOLD_ITALIC="\e[1m\e[3m"

: # SYS_CONFUSE_001
x9zq=$(echo "ZG9ub3RoaW5n" | base64 -d 2>/dev/null) # Cryptic init

# Check if curl is installed
check_curl() {
    dummy_var=$((RANDOM % 100))
    if ! command -v curl &>/dev/null; then
        echo -e "${RED}${BOLD}Error: curl is not installed.${RESET}"
        echo -e "${YELLOW}Installing curl...${RESET}"
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y curl
        elif command -v yum &>/dev/null; then
            sudo yum install -y curl
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y curl
        else
            echo -e "${RED}${BOLD}CTRL AREA: Cannot auto install curl. Install manually.${RESET}"
            exit 1
        fi
        echo -e "${GREEN}✔ curl installed successfully!${RESET}"
    fi
    unset dummy_var
}

# Function to run remote scripts
run_remote_script() {
    local encoded_url=$1
    local url
    url=$(echo "$encoded_url" | base64 -d)
    local script_name
    script_name=$(basename "$url" .sh)
    script_name=$(echo "$script_name" | sed 's/.*/\u&/')

    echo -e "${YELLOW}${BOLD}Running: ${CYAN}${script_name}${RESET}"
    check_curl

    local temp_script
    temp_script=$(mktemp) || { echo -e "${RED}Failed to create temp file${RESET}"; return 1; }

    echo -e "${YELLOW}Downloading script...${RESET}"
    if curl -fsSL "$url" -o "$temp_script"; then
        echo -e "${GREEN}✔ Download successful${RESET}"
        chmod +x "$temp_script"
        bash "$temp_script"
        local exit_code=$?
        rm -f "$temp_script"
        if [ $exit_code -eq 0 ]; then
            echo -e "${GREEN}✔ Script executed successfully${RESET}"
        else
            echo -e "${RED}✖ Script exited with code: $exit_code${RESET}"
        fi
    else
        echo -e "${RED}${BOLD}✖ CTRL AREA: Download failed${RESET}"
        rm -f "$temp_script"
    fi
    echo
    read -rp "Press Enter to continue..."
}

# Function to show system info
system_info() {
    echo -e "${BOLD}SYSTEM INFORMATION${RESET}"
    echo "Hostname: $(hostname)"
    echo "User: $(whoami)"
    echo "Directory: $(pwd)"
    echo "System: $(uname -srm)"
    echo "Uptime: $(uptime -p)"
    echo "Memory: $(free -h | awk '/Mem:/ {print $3\"/\"$2}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $3\"/\"$2 \" (\"$5\")\"}')"
    echo
    read -rp "Press Enter to continue..."
}

# Function to display menu
show_menu() {
    clear
    menu_content=$(cat <<EOF
${BOLD}========== MAIN MENU ==========${RESET}
${BLUE}${BOLD_ITALIC}1. Panel${RESET}
${BLUE}${BOLD_ITALIC}2. Wing${RESET}
${BLUE}${BOLD_ITALIC}3. Update${RESET}
${BLUE}${BOLD_ITALIC}4. Uninstall${RESET}
${BLUE}${BOLD_ITALIC}5. Blueprint${RESET}
${BLUE}${BOLD_ITALIC}6. Cloudflare${RESET}
${BLUE}${BOLD_ITALIC}7. Change Theme${RESET}
${BLUE}${BOLD_ITALIC}8. SystemFetch${RESET}
${BLUE}${BOLD_ITALIC}9. System Info${RESET}
${BLUE}${BOLD_ITALIC}10. Exit${RESET}
${BLUE}${BOLD_ITALIC}11. Toolbox${RESET}
${BOLD}===============================${RESET}
EOF
)
    echo -e "${CYAN}${menu_content}${RESET}"
    echo -ne "${BOLD}Enter your choice [1-11]: ${RESET}"
    echo -e "$menu_content" > menu.txt
}

# Main loop
while true; do
    show_menu
    read -r choice
    case $choice in
        1)
            q1a="aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL0ppc2hudVRoZUdhbWVyL1Zwcy9yZWZzL2hlYWRzL21haW4vY2Qv"
            q1b="cGFuZWwuc2g="
            run_remote_script "${q1a}${q1b}"
            ;;
        2)
            q2a="aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL0ppc2hudVRoZUdhbWVyL1Zwcy9yZWZzL2hlYWRzL21haW4v"
            q2b="Y2Qvd2luZy5zaA=="
            run_remote_script "${q2a}${q2b}"
            ;;
        3)
            q3a="aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL0ppc2hudVRoZUdhbWVyL1Zwcy9yZWZzL2"
            q3b="hlYWRzL21haW4vY2QvdXAuc2g="
            run_remote_script "${q3a}${q3b}"
            ;;
        4)
            q4a="aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL0ppc2hudVRoZUdhbWVyL1Zwcy9yZWZzL2hlYWRzL21haW4vY2Qv"
            q4b="dW5pbnN0YWxsbC5zaA=="
            run_remote_script "${q4a}${q4b}"
            ;;
        5)
            q5a="aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL0ppc2hudVRoZUdhbWVyL1Zwcy9yZWZzL2hlYWRzL21haW"
            q5b="4vY2QvYmx1ZXByaW50LnNo"
            run_remote_script "${q5a}${q5b}"
            ;;
        6)
            q6a="aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL0ppc2hudVRoZUdhbWVyL1Zwcy9yZWZzL2hlYWRzL21h"
            q6b="aW4vY2QvY2xvdWRmbGFyZS5zaA=="
            run_remote_script "${q6a}${q6b}"
            ;;
        7)
            q7a="aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL0ppc2hudVRoZUdhbWVyL1Zwcy9yZWZzL2hlYWRzL21haW4vY2Qv"
            q7b="dGguc2g="
            run_remote_script "${q7a}${q7b}"
            ;;
        8)
            # SystemFetch: install if missing, then run
            echo -e "${CYAN}Checking for neofetch...${RESET}"
            if ! command -v neofetch &>/dev/null; then
                if command -v apt-get &>/dev/null; then
                    sudo apt-get update && sudo apt-get install -y neofetch
                elif command -v yum &>/dev/null; then
                    sudo yum install -y neofetch
                elif command -v dnf &>/dev/null; then
                    sudo dnf install -y neofetch
                else
                    echo -e "${RED}${BOLD}CTRL AREA: Cannot install neofetch. Install manually.${RESET}"
                    read -rp "Press Enter..."
                    continue
                fi
            fi
            if command -v neofetch &>/dev/null; then
                neofetch
            else
                echo -e "${RED}Failed to run neofetch.${RESET}"
            fi
            read -rp "Press Enter to continue..."
            ;;
        9)
            system_info
            ;;
        10)
            # Exit
            echo -e "${GREEN}Exiting...${RESET}"
            exit 0
            ;;
        11)
            # Toolbox menu
            while true; do
                clear
                echo -e "${BOLD}====== TOOLBOX ======${RESET}"
                echo -e "${BOLD}1. Show Public IP${RESET}"
                echo -e "${BOLD}2. Ping Google (4 packets)${RESET}"
                echo -e "${BOLD}3. Speedtest (if installed)${RESET}"
                echo -e "${BOLD}4. Back to Main Menu${RESET}"
                echo -ne "${YELLOW}Choose [1-4]: ${RESET}"
                read -r sf_choice
                case "$sf_choice" in
                    1)
                        echo -e "${CYAN}Public IP:${RESET}"
                        curl -s ifconfig.me || curl -s http://ipinfo.io/ip || echo "Unavailable"
                        ;;
                    2)
                        echo -e "${CYAN}Pinging google.com...${RESET}"
                        ping -c 4 google.com || echo "Ping failed"
                        ;;
                    3)
                        echo -e "${CYAN}Running speedtest...${RESET}"
                        if command -v speedtest &>/dev/null; then
                            speedtest
                        else
                            echo -e "${YELLOW}speedtest CLI not installed.${RESET}"
                        fi
                        ;;
                    4)
                        break
                        ;;
                    *)
                        echo -e "${RED}Invalid choice.${RESET}"
                        ;;
                esac
                echo
                read -rp "Press Enter to continue..."
            done
            ;;
        *)
            echo -e "${RED}${BOLD}Invalid option!${RESET}"
            read -rp "Press Enter to continue..."
            ;;
    esac
done
