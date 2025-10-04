#!/bin/bash
set -euo pipefail

# =============================
# Enhanced Multi-VM Manager (Aayusha Edition)
# =============================

# Function to display header
display_header() {
    clear
    local BRIGHT_MAGENTA='\033[1;95m'
    local BOLD_YELLOW='\033[1;33m'
    local RESET='\033[0m'
    
    # Simple, BOLD header for AAYUSHA
    echo -e "${BRIGHT_MAGENTA}========================================================================"
    echo -e "${BOLD_YELLOW}"
    echo -e "                  A A Y U S H A"
    echo -e "        V I R T U A L   M A N A G E R"
    echo -e "${RESET}"
    echo -e "${BRIGHT_MAGENTA}========================================================================"
    echo
}

# Function to display colored output
print_status() {
    local type=$1
    local message=$2
    
    # Modern ANSI Color Definitions
    local BOLD_CYAN='\033[1;96m'
    local BOLD_GREEN='\033[1;92m'
    local BOLD_YELLOW='\033[1;93m'
    local BOLD_RED='\033[1;91m'
    local BRIGHT_MAGENTA='\033[1;95m'
    local RESET='\033[0m'

    case $type in
        "INFO") echo -e "${BOLD_CYAN}[INFO]${RESET} $message" ;;
        "WARN") echo -e "${BOLD_YELLOW}[WARN]${RESET} $message" ;;
        "ERROR") echo -e "${BOLD_RED}[ERROR]${RESET} $message" ;;
        "SUCCESS") echo -e "${BOLD_GREEN}[SUCCESS]${RESET} $message" ;;
        "INPUT") echo -e "${BRIGHT_MAGENTA}[INPUT]${RESET} $message" ;;
        *) echo "[$type] $message" ;;
    esac
}

# Function to validate input
validate_input() {
    local type=$1
    local value=$2
    
    case $type in
        "number")
            if ! [[ "$value" =~ ^[0-9]+$ ]]; then
                print_status "ERROR" "Must be a number"
                return 1
            fi
            ;;
        "size")
            if ! [[ "$value" =~ ^[0-9]+[GgMm]$ ]]; then
                print_status "ERROR" "Must be a size with unit (e.g., 100G, 512M)"
                return 1
            fi
            ;;
        "port")
            if ! [[ "$value" =~ ^[0-9]+$ ]] || [ "$value" -lt 23 ] || [ "$value" -gt 65535 ]; then
                print_status "ERROR" "Must be a valid port number (23-65535)"
                return 1
            fi
            ;;
        "name")
            if ! [[ "$value" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                print_status "ERROR" "VM name can only contain letters, numbers, hyphens, and underscores"
                return 1
            fi
            ;;
        "username")
            if ! [[ "$value" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
                print_status "ERROR" "Username must start with a letter or underscore, and contain only letters, numbers, hyphens, and underscores"
                return 1
            fi
            ;;
    esac
    return 0
}

# Function to detect package manager and install dependencies
install_qemu() {
    local qemu_package="qemu-system-x86_64"
    print_status "INFO" "Attempting to install QEMU and necessary utilities using a package manager..."
    
    if command -v apt &> /dev/null; then
        print_status "INFO" "Detected apt (Debian/Ubuntu). Running installation..."
        sudo apt update && sudo apt install -y "$qemu_package" cloud-image-utils wget openssl
    elif command -v dnf &> /dev/null; then
        print_status "INFO" "Detected dnf (Fedora/RHEL). Running installation..."
        sudo dnf install -y qemu-kvm qemu-img cloud-utils-growpart wget openssl
    elif command -v yum &> /dev/null; then
        print_status "INFO" "Detected yum (RHEL/CentOS). Running installation..."
        sudo yum install -y qemu-kvm qemu-img cloud-utils-growpart wget openssl
    else
        print_status "ERROR" "Could not detect a common package manager (apt, dnf, yum)."
        print_status "INFO" "Please install the following packages manually: qemu-system-x86_64, cloud-image-utils (or equivalent), wget, and openssl."
        return 1
    fi
    
    if command -v qemu-system-x86_64 &> /dev/null; then
        print_status "SUCCESS" "QEMU and dependencies installed successfully."
        return 0
    else
        print_status "ERROR" "Installation failed or QEMU not found in PATH after install. Please check the logs."
        return 1
    fi
}

# Function to check dependencies
check_dependencies() {
    local deps=("qemu-system-x86_64" "wget" "cloud-localds" "qemu-img" "openssl")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        if [[ " ${missing_deps[*]} " =~ " qemu-system-x86_64 " ]]; then
            print_status "WARN" "Critical dependency missing: QEMU and/or related tools."
            read -r -p "$(print_status "INPUT" "Do you want to attempt automatic installation using sudo? (y/N): ")" install_choice
            if [[ "$install_choice" =~ ^[Yy]$ ]]; then
                if install_qemu; then
                    # Re-check remaining dependencies after QEMU install
                    check_dependencies
                    return
                fi
            fi
        fi
        
        # If QEMU install failed or user declined, list all missing
        local final_missing=()
        for dep in "${deps[@]}"; do
            if ! command -v "$dep" &> /dev/null; then
                final_missing+=("$dep")
            fi
        done
        
        if [ ${#final_missing[@]} -ne 0 ]; then
            print_status "ERROR" "The following dependencies are still missing: ${final_missing[*]}"
            print_status "INFO" "You must install them manually to continue."
            exit 1
        fi
    fi
}

# Function to cleanup temporary files
cleanup() {
    if [ -f "user-data" ]; then rm -f "user-data"; fi
    if [ -f "meta-data" ]; then rm -f "meta-data"; fi
}

# Function to get all VM configurations
get_vm_list() {
    find "$VM_DIR" -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort
}

# Function to load VM configuration
load_vm_config() {
    local vm_name=$1
    local config_file="$VM_DIR/$vm_name.conf"
    
    if [[ -f "$config_file" ]]; then
        # Clear previous variables
        unset VM_NAME OS_TYPE CODENAME IMG_URL HOSTNAME USERNAME PASSWORD
        unset DISK_SIZE MEMORY CPUS SSH_PORT GUI_MODE PORT_FORWARDS IMG_FILE SEED_FILE CREATED
        
        # Load configuration
        # shellcheck disable=SC1090
        source "$config_file"
        return 0
    else
        print_status "ERROR" "Configuration for VM '$vm_name' not found"
        return 1
    fi
}

# Function to save VM configuration
save_vm_config() {
    local config_file="$VM_DIR/$VM_NAME.conf"
    
    cat > "$config_file" <<EOF
VM_NAME="$VM_NAME"
OS_TYPE="$OS_TYPE"
CODENAME="$CODENAME"
IMG_URL="$IMG_URL"
HOSTNAME="$HOSTNAME"
USERNAME="$USERNAME"
PASSWORD="$PASSWORD"
DISK_SIZE="$DISK_SIZE"
MEMORY="$MEMORY"
CPUS="$CPUS"
SSH_PORT="$SSH_PORT"
GUI_MODE="$GUI_MODE"
PORT_FORWARDS="$PORT_FORWARDS"
IMG_FILE="$IMG_FILE"
SEED_FILE="$SEED_FILE"
CREATED="$CREATED"
EOF
    
    print_status "SUCCESS" "Configuration saved to $config_file"
}

# Function to create new VM
create_new_vm() {
    print_status "INFO" "Creating a new VPS/VM"
    
    # OS Selection
    print_status "INFO" "Select an OS to set up:"
    local os_options=()
    local i=1
    for os in "${!OS_OPTIONS[@]}"; do
        echo -e "  \033[1m$i)\033[0m $os" # Use bold for selection number
        os_options[$i]="$os"
        ((i++))
    done
    
    while true; do
        read -p "$(print_status "INPUT" "Enter your choice (1-${#OS_OPTIONS[@]}): ")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#OS_OPTIONS[@]} ]; then
            local os="${os_options[$choice]}"
            IFS='|' read -r OS_TYPE CODENAME IMG_URL DEFAULT_HOSTNAME DEFAULT_USERNAME DEFAULT_PASSWORD <<< "${OS_OPTIONS[$os]}"
            break
        else
            print_status "ERROR" "Invalid selection. Try again."
        fi
    done

    # Custom Inputs with validation
    while true; do
        read -p "$(print_status "INPUT" "Enter VPS name (default: $DEFAULT_HOSTNAME): ")" VM_NAME
        VM_NAME="${VM_NAME:-$DEFAULT_HOSTNAME}"
        if validate_input "name" "$VM_NAME"; then
            # Check if VM name already exists
            if [[ -f "$VM_DIR/$VM_NAME.conf" ]]; then
                print_status "ERROR" "VM with name '$VM_NAME' already exists"
            else
                break
            fi
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Enter hostname (default: $VM_NAME): ")" HOSTNAME
        HOSTNAME="${HOSTNAME:-$VM_NAME}"
        if validate_input "name" "$HOSTNAME"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Enter username (default: $DEFAULT_USERNAME): ")" USERNAME
        USERNAME="${USERNAME:-$DEFAULT_USERNAME}"
        if validate_input "username" "$USERNAME"; then
            break
        fi
    done

    while true; do
        read -s -p "$(print_status "INPUT" "Enter password (default: $DEFAULT_PASSWORD): ")" PASSWORD
        PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"
        echo
        if [ -n "$PASSWORD" ]; then
            break
        else
            print_status "ERROR" "Password cannot be empty"
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Disk size (default: 20G): ")" DISK_SIZE
        DISK_SIZE="${DISK_SIZE:-20G}"
        if validate_input "size" "$DISK_SIZE"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Memory in MB (default: 2048): ")" MEMORY
        MEMORY="${MEMORY:-2048}"
        if validate_input "number" "$MEMORY"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Number of CPUs (default: 2): ")" CPUS
        CPUS="${CPUS:-2}"
        if validate_input "number" "$CPUS"; then
            break
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "SSH Port (default: 2222): ")" SSH_PORT
        SSH_PORT="${SSH_PORT:-2222}"
        if validate_input "port" "$SSH_PORT"; then
            # Check if port is already in use
            if ss -tln 2>/dev/null | grep -q ":$SSH_PORT "; then
                print_status "ERROR" "Port $SSH_PORT is already in use"
            else
                break
            fi
        fi
    done

    while true; do
        read -p "$(print_status "INPUT" "Enable GUI mode? (y/n, default: n): ")" gui_input
        GUI_MODE=false
        gui_input="${gui_input:-n}"
        if [[ "$gui_input" =~ ^[Yy]$ ]]; then 
            GUI_MODE=true
            break
        elif [[ "$gui_input" =~ ^[Nn]$ ]]; then
            break
        else
            print_status "ERROR" "Please answer y or n"
        fi
    done

    # Additional network options
    read -p "$(print_status "INPUT" "Additional port forwards (e.g., 8080:80, press Enter for none): ")" PORT_FORWARDS

    IMG_FILE="$VM_DIR/$VM_NAME.img"
    SEED_FILE="$VM_DIR/$VM_NAME-seed.iso"
    CREATED="$(date)"

    # Download and setup VM image
    setup_vm_image
    
    # Save configuration
    save_vm_config
}

# Function to setup VM image
setup_vm_image() {
    print_status "INFO" "Downloading and preparing image..."
    
    # Create VM directory if it doesn't exist
    mkdir -p "$VM_DIR"
    
    # Check if image already exists
    if [[ -f "$IMG_FILE" ]]; then
        print_status "INFO" "Image file already exists. Skipping download."
    else
        print_status "INFO" "Downloading image from $IMG_URL..."
        if ! wget --progress=bar:force "$IMG_URL" -O "$IMG_FILE.tmp"; then
            print_status "ERROR" "Failed to download image from $IMG_URL"
            exit 1
        fi
        mv "$IMG_FILE.tmp" "$IMG_FILE"
    fi
    
    # Resize the disk image if needed
    if ! qemu-img resize "$IMG_FILE" "$DISK_SIZE" 2>/dev/null; then
        print_status "WARN" "Failed to resize disk image. Creating new image with specified size..."
        # Create a new image with the specified size
        rm -f "$IMG_FILE"
        qemu-img create -f qcow2 -F qcow2 -b "$IMG_FILE" "$IMG_FILE.tmp" "$DISK_SIZE" 2>/dev/null || \
        qemu-img create -f qcow2 "$IMG_FILE" "$DISK_SIZE"
        if [ -f "$IMG_FILE.tmp" ]; then
            mv "$IMG_FILE.tmp" "$IMG_FILE"
        fi
    fi

    # cloud-init configuration
    cat > user-data <<EOF
#cloud-config
hostname: $HOSTNAME
ssh_pwauth: true
disable_root: false
users:
  - name: $USERNAME
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    password: $(openssl passwd -6 "$PASSWORD" | tr -d '\n')
chpasswd:
  list: |
    root:$PASSWORD
    $USERNAME:$PASSWORD
  expire: false
EOF

    cat > meta-data <<EOF
instance-id: iid-$VM_NAME
local-hostname: $HOSTNAME
EOF

    if ! cloud-localds "$SEED_FILE" user-data meta-data; then
        print_status "ERROR" "Failed to create cloud-init seed image"
        exit 1
    fi
    
    print_status "SUCCESS" "VPS '$VM_NAME' setup complete."
}

# Function to start a VM
start_vm() {
    local vm_name=$1
    
    if load_vm_config "$vm_name"; then
        print_status "INFO" "Starting VPS: $vm_name"
        print_status "INFO" "To connect via SSH: ssh -p $SSH_PORT $USERNAME@localhost"
        print_status "INFO" "Password: $PASSWORD"
        
        # Check if image file exists
        if [[ ! -f "$IMG_FILE" ]]; then
            print_status "ERROR" "VM image file not found: $IMG_FILE"
            return 1
        fi
        
        # Check if seed file exists
        if [[ ! -f "$SEED_FILE" ]]; then
            print_status "WARN" "Seed file not found, recreating..."
            setup_vm_image
        fi
        
        # Base QEMU command
        local qemu_cmd=(
            qemu-system-x86_64
            -name "$vm_name" # Add name for easier process identification
            -enable-kvm
            -m "$MEMORY"
            -smp "$CPUS"
            -cpu host
            -drive "file=$IMG_FILE,format=qcow2,if=virtio"
            -drive "file=$SEED_FILE,format=raw,if=virtio"
            -boot order=c
            -device virtio-net-pci,netdev=n0
            -netdev "user,id=n0,hostfwd=tcp::$SSH_PORT-:22"
        )

        # Add additional port forwards if specified
        if [[ -n "$PORT_FORWARDS" ]]; then
            IFS=',' read -ra forwards <<< "$PORT_FORWARDS"
            local net_id_counter=1 # Start counter for additional network devices
            for forward in "${forwards[@]}"; do
                IFS=':' read -r host_port guest_port <<< "$forward"
                local net_id="n$net_id_counter"
                
                # Check for empty ports from bad split (e.g. trailing comma)
                if [[ -z "$host_port" || -z "$guest_port" ]]; then
                    print_status "WARN" "Skipping invalid port forward segment: '$forward'"
                    continue
                fi
                
                # Add a new network device and netdev rule
                qemu_cmd+=(-device "virtio-net-pci,netdev=$net_id")
                qemu_cmd+=(-netdev "user,id=$net_id,hostfwd=tcp::$host_port-:$guest_port")
                ((net_id_counter++))
            done
        fi

        # Add GUI or console mode
        if [[ "$GUI_MODE" == true ]]; then
            qemu_cmd+=(-vga virtio -display gtk,gl=on)
        else
            qemu_cmd+=(-nographic -serial mon:stdio)
        fi

        # Add performance enhancements
        qemu_cmd+=(
            -device virtio-balloon-pci
            -object rng-random,filename=/dev/urandom,id=rng0
            -device virtio-rng-pci,rng=rng0
        )

        print_status "INFO" "Starting QEMU..."
        "${qemu_cmd[@]}"
        
        print_status "INFO" "VPS $vm_name has been shut down"
    fi
}

# Function to delete a VM
delete_vm() {
    local vm_name=$1
    
    print_status "WARN" "This will permanently delete VPS '$vm_name' and all its data!"
    read -p "$(print_status "INPUT" "Are you sure? (y/N): ")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if load_vm_config "$vm_name"; then
            rm -f "$IMG_FILE" "$SEED_FILE" "$VM_DIR/$vm_name.conf"
            print_status "SUCCESS" "VPS '$vm_name' has been deleted"
        fi
    else
        print_status "INFO" "Deletion cancelled"
    fi
}

# Function to show VM info
show_vm_info() {
    local vm_name=$1
    local BOLD_CYAN='\033[1;96m'
    local BRIGHT_MAGENTA='\033[1;95m'
    local RESET='\033[0m'
    
    if load_vm_config "$vm_name"; then
        echo
        echo -e "${BRIGHT_MAGENTA}VPS Configuration for: ${BOLD_CYAN}$vm_name${RESET}"
        echo -e "${BRIGHT_MAGENTA}==========================================${RESET}"
        echo "OS: $OS_TYPE ($CODENAME)"
        echo "Hostname: $HOSTNAME"
        echo "Username: $USERNAME"
        echo "Password: $PASSWORD"
        echo "---"
        echo "SSH Port: $SSH_PORT"
        echo "Memory: $MEMORY MB"
        echo "CPUs: $CPUS"
        echo "Disk: $DISK_SIZE"
        echo "GUI Mode: $GUI_MODE"
        echo "Port Forwards: ${PORT_FORWARDS:-None}"
        echo "---"
        echo "Created: $CREATED"
        echo "Image File: $IMG_FILE"
        echo -e "${BRIGHT_MAGENTA}==========================================${RESET}"
        echo
        read -p "$(print_status "INPUT" "Press Enter to continue...")"
    fi
}

# Function to check if VM is running
is_vm_running() {
    local vm_name=$1
    # Check for process by VM name passed to QEMU -name flag
    if pgrep -f "qemu-system-x86_64.*-name $vm_name" >/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to stop a running VM
stop_vm() {
    local vm_name=$1
    
    if load_vm_config "$vm_name"; then
        if is_vm_running "$vm_name"; then
            print_status "INFO" "Stopping VPS: $vm_name"
            # Attempt graceful kill first
            pkill -f "qemu-system-x86_64.*-name $vm_name"
            sleep 3
            if is_vm_running "$vm_name"; then
                print_status "WARN" "VPS did not stop gracefully, forcing termination..."
                pkill -9 -f "qemu-system-x86_64.*-name $vm_name"
            fi
            print_status "SUCCESS" "VPS $vm_name stopped"
        else
            print_status "INFO" "VPS $vm_name is not running"
        fi
    fi
}

# Function to edit VM configuration
edit_vm_config() {
    local vm_name=$1
    
    if load_vm_config "$vm_name"; then
        print_status "INFO" "Editing VPS: $vm_name (NOTE: Hostname, Username, Password changes require the VPS to be restarted.)"
        
        while true; do
            echo -e "\n\033[1;96m[ Configuration Editor ]\033[0m"
            echo "  1) Hostname (Current: $HOSTNAME)"
            echo "  2) Username (Current: $USERNAME)"
            echo "  3) Password (Current: ****)"
            echo "  4) SSH Port (Current: $SSH_PORT)"
            echo "  5) GUI Mode (Current: $GUI_MODE)"
            echo "  6) Port Forwards (Current: ${PORT_FORWARDS:-None})"
            echo "  7) Memory (RAM) (Current: $MEMORY MB)"
            echo "  8) CPU Count (Current: $CPUS)"
            echo "  9) Disk Size (Current: $DISK_SIZE) - Changes only applied via Resize Disk menu"
            echo "  0) Back to VM actions menu"
            
            read -p "$(print_status "INPUT" "Enter your choice: ")" edit_choice
            
            case $edit_choice in
                1)
                    while true; do
                        read -p "$(print_status "INPUT" "Enter new hostname: ")" new_hostname
                        new_hostname="${new_hostname:-$HOSTNAME}"
                        if validate_input "name" "$new_hostname"; then
                            HOSTNAME="$new_hostname"
                            break
                        fi
                    done
                    ;;
                2)
                    while true; do
                        read -p "$(print_status "INPUT" "Enter new username: ")" new_username
                        new_username="${new_username:-$USERNAME}"
                        if validate_input "username" "$new_username"; then
                            USERNAME="$new_username"
                            break
                        fi
                    done
                    ;;
                3)
                    while true; do
                        read -s -p "$(print_status "INPUT" "Enter new password: ")" new_password
                        new_password="${new_password:-$PASSWORD}"
                        echo
                        if [ -n "$new_password" ]; then
                            PASSWORD="$new_password"
                            break
                        else
                            print_status "ERROR" "Password cannot be empty"
                        fi
                    done
                    ;;
                4)
                    while true; do
                        read -p "$(print_status "INPUT" "Enter new SSH port: ")" new_ssh_port
                        new_ssh_port="${new_ssh_port:-$SSH_PORT}"
                        if validate_input "port" "$new_ssh_port"; then
                            # Check if port is already in use
                            if [ "$new_ssh_port" != "$SSH_PORT" ] && ss -tln 2>/dev/null | grep -q ":$new_ssh_port "; then
                                print_status "ERROR" "Port $new_ssh_port is already in use"
                            else
                                SSH_PORT="$new_ssh_port"
                                break
                            fi
                        fi
                    done
                    ;;
                5)
                    while true; do
                        read -p "$(print_status "INPUT" "Enable GUI mode? (y/n): ")" gui_input
                        gui_input="${gui_input:-}"
                        if [[ "$gui_input" =~ ^[Yy]$ ]]; then 
                            GUI_MODE=true
                            break
                        elif [[ "$gui_input" =~ ^[Nn]$ ]]; then
                            GUI_MODE=false
                            break
                        elif [ -z "$gui_input" ]; then
                            # Keep current value if user just pressed Enter
                            break
                        else
                            print_status "ERROR" "Please answer y or n"
                        fi
                    done
                    ;;
                6)
                    read -p "$(print_status "INPUT" "Additional port forwards (current: ${PORT_FORWARDS:-None}): ")" new_port_forwards
                    PORT_FORWARDS="${new_port_forwards:-$PORT_FORWARDS}"
                    ;;
                7)
                    while true; do
                        read -p "$(print_status "INPUT" "Enter new memory in MB: ")" new_memory
                        new_memory="${new_memory:-$MEMORY}"
                        if validate_input "number" "$new_memory"; then
                            MEMORY="$new_memory"
                            break
                        fi
                    done
                    ;;
                8)
                    while true; do
                        read -p "$(print_status "INPUT" "Enter new CPU count: ")" new_cpus
                        new_cpus="${new_cpus:-$CPUS}"
                        if validate_input "number" "$new_cpus"; then
                            CPUS="$new_cpus"
                            break
                        fi
                    done
                    ;;
                9)
                    print_status "INFO" "Use the 'Resize VPS Disk' option from the actions menu to apply disk size changes."
                    ;;
                0)
                    return 0
                    ;;
                *)
                    print_status "ERROR" "Invalid selection"
                    continue
                    ;;
            esac
            
            # Recreate seed image with new configuration if user/password/hostname changed
            if [[ "$edit_choice" -le 3 ]]; then
                print_status "INFO" "Updating cloud-init configuration (requires VPS restart)..."
                setup_vm_image
            fi
            
            # Save configuration
            save_vm_config
            
            read -p "$(print_status "INPUT" "Continue editing? (y/N): ")" continue_editing
            if [[ ! "$continue_editing" =~ ^[Yy]$ ]]; then
                break
            fi # <-- Fixed: Removed the extraneous closing brace "}" here.
        done
    fi
}

# Function to resize VM disk
resize_vm_disk() {
    local vm_name=$1
    
    if load_vm_config "$vm_name"; then
        if is_vm_running "$vm_name"; then
            print_status "ERROR" "VPS $vm_name must be stopped before resizing the disk."
            return 1
        fi
        
        print_status "INFO" "Current disk size: $DISK_SIZE"
        
        while true; do
            read -p "$(print_status "INPUT" "Enter new disk size (e.g., 50G): ")" new_disk_size
            if validate_input "size" "$new_disk_size"; then
                if [[ "$new_disk_size" == "$DISK_SIZE" ]]; then
                    print_status "INFO" "New disk size is the same as current size. No changes made."
                    return 0
                fi
                
                # Check if new size is smaller than current (not recommended)
                local current_size_num=${DISK_SIZE%[GgMm]}
                local new_size_num=${new_disk_size%[GgMm]}
                local current_unit=${DISK_SIZE: -1}
                local new_unit=${new_disk_size: -1}
                
                # Convert both to MB for comparison
                if [[ "$current_unit" =~ [Gg] ]]; then
                    current_size_num=$((current_size_num * 1024))
                fi
                if [[ "$new_unit" =~ [Gg] ]]; then
                    new_size_num=$((new_size_num * 1024))
                fi
                
                if [[ $new_size_num -lt $current_size_num ]]; then
                    print_status "WARN" "Shrinking disk size is not recommended and may cause data loss!"
                    read -p "$(print_status "INPUT" "Are you sure you want to continue? (y/N): ")" confirm_shrink
                    if [[ ! "$confirm_shrink" =~ ^[Yy]$ ]]; then
                        print_status "INFO" "Disk resize cancelled."
                        return 0
                    fi
                fi
                
                # Resize the disk
                print_status "INFO" "Resizing disk to $new_disk_size... (You may need to resize the partition inside the VPS after next boot)"
                if qemu-img resize "$IMG_FILE" "$new_disk_size"; then
                    DISK_SIZE="$new_disk_size"
                    save_vm_config
                    print_status "SUCCESS" "Disk resized successfully to $new_disk_size"
                else
                    print_status "ERROR" "Failed to resize disk"
                    return 1
                fi
                break
            fi
        done
    fi
}

# Function to show VM performance metrics
show_vm_performance() {
    local vm_name=$1
    
    if load_vm_config "$vm_name"; then
        if is_vm_running "$vm_name"; then
            print_status "INFO" "Performance metrics for VPS: $vm_name"
            echo "=========================================="
            
            # Get QEMU process ID
            local qemu_pid=$(pgrep -f "qemu-system-x86_64.*-name $vm_name")
            if [[ -n "$qemu_pid" ]]; then
                # Show process stats
                echo -e "\033[1;96mQEMU Process Stats:\033[0m"
                ps -p "$qemu_pid" -o pid,%cpu,%mem,sz,rss,vsz,cmd --no-headers
                echo
                
                # Show memory usage
                echo -e "\033[1;96mHost Memory Usage:\033[0m"
                free -h
                echo
                
                # Show disk usage
                echo -e "\033[1;96mVPS Image Disk Usage:\033[0m"
                df -h "$IMG_FILE" 2>/dev/null || du -h "$IMG_FILE"
            else
                print_status "ERROR" "Could not find RUNNING QEMU process for VPS $vm_name"
            fi
        else
            print_status "INFO" "VPS $vm_name is not running. Showing configured resources."
            echo "Configuration:"
            echo "  Memory: $MEMORY MB"
            echo "  CPUs: $CPUS"
            echo "  Disk: $DISK_SIZE"
        fi
        echo "=========================================="
        read -p "$(print_status "INPUT" "Press Enter to continue...")"
    fi
}

# --- New Submenu Functions ---

# Function for actions on a single selected VM
vm_action_submenu() {
    local vm_name=$1
    local BRIGHT_MAGENTA='\033[1;95m'
    local BRIGHT_GREEN='\033[1;92m'
    local BOLD_CYAN='\033[1;96m'
    local RESET='\033[0m'

    while true; do
        display_header
        echo -e "${BRIGHT_MAGENTA}Actions for VPS: ${BOLD_CYAN}$vm_name${RESET}"
        echo -e "--------------------------------------------------------"

        local status="${BRIGHT_MAGENTA}Stopped${RESET}"
        local start_stop_option=2
        if is_vm_running "$vm_name"; then
            status="${BRIGHT_GREEN}Running${RESET}"
            echo -e "  \033[1;96m1)\033[0m Stop VPS"
        else
            echo -e "  \033[1;96m1)\033[0m Start VPS"
            start_stop_option=1
        fi
        
        echo "Status: $status"
        echo
        echo -e "  \033[1;96m2)\033[0m Show VPS Info"
        echo -e "  \033[1;96m3)\033[0m Edit VPS Configuration"
        echo -e "  \033[1;96m4)\033[0m Resize VPS Disk"
        echo -e "  \033[1;96m5)\033[0m Show VPS Performance Metrics"
        echo -e "  \033[1;96m6)\033[0m \033[1;91mDelete VPS (Permanent)\033[0m"
        echo -e "  \033[1;96m0)\033[0m Back to VPS List"
        echo -e "--------------------------------------------------------"

        read -p "$(print_status "INPUT" "Enter your choice: ")" action_choice
        
        case $action_choice in
            1)
                if [ "$start_stop_option" -eq 1 ]; then
                    start_vm "$vm_name"
                else
                    stop_vm "$vm_name"
                fi
                read -p "$(print_status "INPUT" "Press Enter to continue...")"
                ;;
            2)
                show_vm_info "$vm_name" 
                ;;
            3)
                edit_vm_config "$vm_name"
                read -p "$(print_status "INPUT" "Press Enter to return to the actions menu...")"
                ;;
            4)
                resize_vm_disk "$vm_name"
                read -p "$(print_status "INPUT" "Press Enter to return to the actions menu...")"
                ;;
            5)
                show_vm_performance "$vm_name" 
                ;;
            6)
                delete_vm "$vm_name"
                # If deleted, break out of this loop and return to the list
                return 
                ;;
            0)
                return
                ;;
            *)
                print_status "ERROR" "Invalid option"
                read -p "$(print_status "INPUT" "Press Enter to continue...")"
                ;;
        esac
    done
}

# Function for listing and selecting existing VMs
manage_existing_vms_submenu() {
    local vms=("$@") # Get array of VM names passed as argument
    local vm_count=${#vms[@]}
    local BRIGHT_MAGENTA='\033[1;95m'
    local BRIGHT_GREEN='\033[1;92m'
    local RESET='\033[0m'

    while true; do
        display_header
        echo -e "${BRIGHT_MAGENTA}Manage Existing VPS/VMs${RESET}"
        echo -e "--------------------------------------------------------"

        print_status "INFO" "Select a VPS to act on:"
        for i in "${!vms[@]}"; do
            local status="${BRIGHT_MAGENTA}Stopped${RESET}"
            if is_vm_running "${vms[$i]}"; then
                status="${BRIGHT_GREEN}Running${RESET}"
            fi
            printf "  \033[1;96m%2d)\033[0m %-20s [%s]\n" $((i+1)) "${vms[$i]}" "$status"
        done
        echo -e "  \033[1;96m0)\033[0m Back to Main Menu"
        echo -e "--------------------------------------------------------"

        read -p "$(print_status "INPUT" "Enter VPS number or 0: ")" vm_num

        if [[ "$vm_num" == "0" ]]; then
            return # Back to main menu
        elif [[ "$vm_num" =~ ^[0-9]+$ ]] && [ "$vm_num" -ge 1 ] && [ "$vm_num" -le $vm_count ]; then
            local selected_vm="${vms[$((vm_num-1))]}"
            vm_action_submenu "$selected_vm"
            # Re-fetch VM list in case one was deleted in the action submenu
            vms=($(get_vm_list))
            vm_count=${#vms[@]}
            if [ $vm_count -eq 0 ]; then
                print_status "INFO" "All VPS instances deleted. Returning to main menu."
                read -p "$(print_status "INPUT" "Press Enter to continue...")"
                return 
            fi
        else
            print_status "ERROR" "Invalid selection"
            read -p "$(print_status "INPUT" "Press Enter to continue...")"
        fi
    done
}


# Main menu function
main_menu() {
    local BRIGHT_MAGENTA='\033[1;95m'
    local RESET='\033[0m'
    
    while true; do
        display_header
        
        local vms=($(get_vm_list))
        local vm_count=${#vms[@]}
        
        echo -e "${BRIGHT_MAGENTA}Main Menu:${RESET}"
        echo -e "  \033[1;96m1)\033[0m Create VPS" # Primary Action
        
        if [ $vm_count -gt 0 ]; then
            print_status "INFO" "Existing VPS/VMs: $vm_count found"
            echo -e "  \033[1;96m2)\033[0m Manage Existing VPS/VMs" # Consolidated Management
        fi
        
        echo -e "  \033[1;96m0)\033[0m Exit"
        echo
        
        read -p "$(print_status "INPUT" "Enter your choice: ")" choice
        
        case $choice in
            1)
                create_new_vm
                ;;
            2)
                if [ $vm_count -gt 0 ]; then
                    # Pass the array of VM names to the new submenu function
                    manage_existing_vms_submenu "${vms[@]}" 
                else
                    print_status "ERROR" "No existing VMs to manage."
                fi
                ;;
            0)
                print_status "INFO" "Goodbye!"
                exit 0
                ;;
            *)
                print_status "ERROR" "Invalid option"
                ;;
        esac
        
        read -p "$(print_status "INPUT" "Press Enter to return to the menu...")"
    done
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Initialize paths
VM_DIR="${VM_DIR:-$HOME/vms}"
mkdir -p "$VM_DIR"

# Supported OS list
declare -A OS_OPTIONS=(
    ["Ubuntu 22.04"]="ubuntu|jammy|https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img|ubuntu22|ubuntu|ubuntu"
    ["Ubuntu 24.04"]="ubuntu|noble|https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img|ubuntu24|ubuntu|ubuntu"
    ["Debian 11"]="debian|bullseye|https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2|debian11|debian|debian"
    ["Debian 12"]="debian|bookworm|https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2|debian12|debian|debian"
    ["Fedora 40"]="fedora|40|https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-40-1.14.x86_64.qcow2|fedora40|fedora|fedora"
    ["CentOS Stream 9"]="centos|stream9|https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2|centos9|centos|centos"
    ["AlmaLinux 9"]="almalinux|9|https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2|almalinux9|alma|alma"
    ["Rocky Linux 9"]="rockylinux|9|https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud.latest.x86_64.qcow2|rocky9|rocky|rocky"
)

# Check dependencies and install if needed
check_dependencies

# Start the main menu
main_menu
