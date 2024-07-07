#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   sleep 1
   exit 1
fi

# just press key to continue
press_key(){
 read -p "Press any key to continue..."
}

# Define a function to colorize text
colorize() {
    local color="$1"
    local text="$2"
    local style="${3:-normal}"
    
    # Define ANSI color codes
    local black="\033[30m"
    local red="\033[31m"
    local green="\033[32m"
    local yellow="\033[33m"
    local blue="\033[34m"
    local magenta="\033[35m"
    local cyan="\033[36m"
    local white="\033[37m"
    local reset="\033[0m"
    
    # Define ANSI style codes
    local normal="\033[0m"
    local bold="\033[1m"
    local underline="\033[4m"
    # Select color code
    local color_code
    case $color in
        black) color_code=$black ;;
        red) color_code=$red ;;
        green) color_code=$green ;;
        yellow) color_code=$yellow ;;
        blue) color_code=$blue ;;
        magenta) color_code=$magenta ;;
        cyan) color_code=$cyan ;;
        white) color_code=$white ;;
        *) color_code=$reset ;;  # Default case, no color
    esac
    # Select style code
    local style_code
    case $style in
        bold) style_code=$bold ;;
        underline) style_code=$underline ;;
        normal | *) style_code=$normal ;;  # Default case, normal text
    esac

    # Print the colored and styled text
    echo -e "${style_code}${color_code}${text}${reset}"
}

# Function to check vpncloud installation status
vpncloud_core_status() {
    if command -v vpncloud &> /dev/null; then
    	colorize green "VPNCloud Core: Installed"
    	return 0
	else
    	colorize red "VPNCloud Core: not found"
    	return 1
    fi
}

# Function to download and install vpncloud
install_vpncloud() {
    # check if core installed already
	if vpncloud_core_status; then
		return 0
	fi
	if ! command -v apt-get &> /dev/null; then
		colorize red "Error: Unsupported package manager. Please install vpncloud manually." bold
		sleep 1
		exit 1
	fi
	
	URL_X86="https://github.com/dswd/vpncloud/releases/download/v2.3.0/vpncloud_2.3.0_amd64.deb"
    URL_ARM_SOFT="https://github.com/dswd/vpncloud/releases/download/v2.3.0/vpncloud_2.3.0_arm64.deb"              
    URL_ARM_HARD="https://github.com/dswd/vpncloud/releases/download/v2.3.0/vpncloud_2.3.0_armhf.deb"
    
    # Detect the system architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        URL=$URL_X86
    elif [ "$ARCH" = "armv7l" ] || [ "$ARCH" = "aarch64" ]; then
        if [ "$(ldd /bin/ls | grep -c 'armhf')" -eq 1 ]; then
            URL=$URL_ARM_HARD
        else
            URL=$URL_ARM_SOFT
        fi
    else
        colorize red "Unsupported architecture: $ARCH" bold
        exit 1
   
    fi


    if [ -z "URL" ]; then
    	colorize red "Failed to retrieve download URL." bold
        sleep 1
        exit 1
    fi

    DOWNLOAD_DIR="/tmp"
    colorize yellow "Downloading VPNCloud from $URL..."
    sleep 1
    curl -sSL -o "$DOWNLOAD_DIR/vpncloud.deb" "$URL"
    dpkg -i "$DOWNLOAD_DIR/vpncloud.deb"
    apt-get install -f
    echo
    colorize green "VPNCloud installation completed" bold
	sleep 1
    rm -rf "$DOWNLOAD_DIR/vpncloud.deb"
}

# Install vpncloud
install_vpncloud

# Function to display ASCII logo
display_logo() {   
    echo -e "${CYAN}"
    cat << "EOF"
 (  (  (   ((     (   .     (   (    
 )\ )\ )\  ))\   ())(   (   )\  \)   
((_)(_)(_)((_)))((_))\  )\ ((_) )\)_ 
\ \ / / _ \ \| |/ __| |((_)(_)) )\| |
 \   /|  _/ .  | (__| | _ \ || | _` |
  \_/ |_| |_|\_|\___|_|___/\_._|__/_|
  
  High Performance peer-to-peer VPN	
EOF
echo -e "${NC}"
}

# Function to display server location and IP
display_header() {
	echo -e "╔════════════════════════════════════════╗"
    echo -e "║ Version: v0.9                          ║"
    echo -e "║ Github: github.com/Musixal/VPNCloud    ║"
    echo -e "║ Telegram Channel: @Gozar_Xray          ║"
    echo -e "║ $(vpncloud_core_status)               ║"
    echo -e "╚════════════════════════════════════════╝"
}



connect_mesh(){
	clear
	colorize cyan "	Connect to the Mesh Network Settings" bold
	echo
	colorize red "* Attention:" bold
	colorize yellow "- Options with [*] are mandatory and options with [-] are optional"
	colorize yellow "- TUN is slightly faster and TAP is more flexible concerning supported protocols and setups"
	colorize yellow "- Leave Peer addresses blank to enable reverse mode"
	echo
	
	CONFIG='/etc/vpncloud/musix.net'
	if [ -f $CONFIG ];then
		colorize red "Existing config found! Please remove the tunnel first." bold
		echo
		press_key
		return 1
	fi
	
	
	#Virtual IP address
	echo -ne "${RED}[+]${NC} Virtual IP Address (e.g. 10.0.0.1): "
	read -r VIRTUAL_IP
	if [ -z "$VIRTUAL_IP" ]; then
		colorize red "Invalid value for virtual ip address"
		sleep 2
		return 1
	fi
	
	# Device Type
	echo
	echo -ne "${GREEN}[-]${NC} Device type (tap/${GREEN}tun${NC}): "
	read -r DEVICE_TYPE
	
	if [ -z "$DEVICE_TYPE" ]; then
		DEVICE_TYPE="tun"
	fi
	
	if ! [[ "$DEVICE_TYPE" != "tun" ]] && ! [[ "$DEVICE_TYPE" != "tap" ]]; then
		colorize red "Invalid device type, changing to tun as default value" bold
		DEVICE_TYPE="tun"
	fi

	
	# Listen Port
	echo
	echo -ne "${GREEN}[-]${NC} Listen Port (Default ${GREEN}3210${NC}): "
	read -r LISTEN_PORT
		
	if [ -z "$LISTEN_PORT" ]; then
		LISTEN_PORT="3210"
	fi
	
	# PASSWORD
	echo
	echo -ne "${GREEN}[-]${NC} Password (Leave it blank to use default password): "
	read -r PASSWORD
		
	if [ -z "$PASSWORD" ]; then
		PASSWORD="musixal"
	fi
	
	# ENCRYPTION
	echo
	echo -ne "${GREEN}[-]${NC} Encryption Enabled: (${GREEN}yes${NC}/no): "
	read ENCRYPTION
	
	# Process the ENCRYPTION input
	case "$ENCRYPTION" in
	    y|Y|yes|YES|"")
	        colorize green "Encryption enabled." 
ALG="  algorithms:
    - AES128
    - AES256
    - CHACHA20"
	        ;;
	    n|N|no|NO)
	        colorize yellow "Encryption disabled." 
ALG="  algorithms:
    - PLAIN"
	        ;;
	    *)
	        colorize red "Invalid input. Assuming encryption is enabled."
ALG="  algorithms:
    - AES128
    - AES256
    - CHACHA20"
	        ;;
	esac
		
	# Write the config, round 1
	cat << EOF >> "$CONFIG"
device:
  type: $DEVICE_TYPE
  name: vpncloud%d
  path: ~
  fix-rp-filter: false
ip: $VIRTUAL_IP
advertise-addresses: []
ifup: ~
ifdown: ~
crypto:
  password: "$PASSWORD"
  private-key: ~
  public-key: ~
  trusted-keys: []
$ALG
listen: "$LISTEN_PORT"
EOF
	
	#PEERS
	echo
	echo -ne "${GREEN}[-]${NC} Peer addresses (comma separated, IPv6 with bracket): "
	read -r PEERS
	
	# Check if PEERS variable is empty
	if [ -z "$PEERS" ]; then
	    colorize yellow "No peer addresses provided. Reverse mode enabled"
	    echo "peers: []" >> $CONFIG
	else
		echo "peers:" >> $CONFIG
  		PEERS=$(echo "$PEERS" | tr -d '[:space:]')
		IFS=',' read -ra PEER_LIST <<< "$PEERS"
		for peer in "${PEER_LIST[@]}"; do
			echo "  - \"$peer\"" >> $CONFIG
		done
	fi

	#PeerTimout
	echo
	echo -ne "${GREEN}[-]${NC} Peer timeout in seconds (Default ${GREEN}300${NC}): "
	read -r TIMEOUT
	if [ -z "$TIMEOUT" ]; then
		TIMEOUT="300"
	fi
	
	#KEEP ALIVE
	echo
	echo -ne "${GREEN}[-]${NC} Keepalive interval in seconds (0 for default): "
	read -r KEEPALIVE
	if [ -z "$KEEPALIVE" ]; then
		KEEPALIVE="~"
	elif [[ "$KEEPALIVE" == "0" ]]; then
		KEEPALIVE="~"
	fi
		
	# Write the config, round 2	
	cat << EOF >> "$CONFIG"
peer-timeout: $TIMEOUT
keepalive: $KEEPALIVE
beacon:
  store: ~
  load: ~
  interval: 3600
  password: ~
mode: normal
switch-timeout: 300
claims: []
auto-claim: true
port-forwarding: true
pid-file: ~
stats-file: ~
statsd:
  server: ~
  prefix: ~
user: ~
group: ~
hook: ~
hooks: {}
EOF

    # Reload systemd to read the new unit file
    systemctl daemon-reload >/dev/null 2>&1
	echo
    # Enable and start the service to start on boot
    if systemctl enable --now vpncloud@musix >/dev/null 2>&1; then
        colorize green "VPNCloud service enabled to start on boot and started." bold
    else
        colorize red "Failed to enable vpncloud service. Please check your configuration." bold
    fi
     
    echo
	press_key
}

service_status(){
	clear
	systemctl status vpncloud@musix
	press_key
}
restart_service(){
	echo
	systemctl restart vpncloud@musix &> /dev/null
	
	# Check the exit status of the systemctl command
	if [ $? -eq 0 ]; then
	    colorize green "VPNCloud Service restarted successfully" bold
	else
	    colorize red "Failed to restart the VPNCloud service" bold
	fi
	
	sleep 2
			
}

view_logs(){
	clear	
	journalctl -xeu vpncloud@musix.service
}

remove_tunnel(){
	echo
	systemctl stop vpncloud@musix &> /dev/null
	if [ $? -eq 0 ]; then
	    colorize green "VPNCloud Service stopped successfully" bold
	else
	    colorize red "Failed to stop the VPNCloud service" bold
	fi
	
	echo
	systemctl disable vpncloud@musix &> /dev/null
	if [ $? -eq 0 ]; then
	    colorize green "VPNCloud Service disabled successfully" bold
	else
	    colorize red "Failed to stop the disable service" bold
	fi
	
	echo
	if [ -f '/etc/vpncloud/musix.net' ]; then
		rm -f '/etc/vpncloud/musix.net'
		 colorize green "VPNCloud config file deleted successfully" bold
	else
		 colorize red "VPNCloud config file not found" bold
	fi
	echo
	press_key
}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\e[36m'
MAGENTA="\e[95m"
NC='\033[0m' # No Color

# Function to display menu
display_menu() {
    clear
    display_logo
    display_header
    echo
    colorize green " 1. Connect to the Mesh Network" bold
    colorize cyan " 2. View service status"
    colorize reset " 3. View logs"
    colorize yellow " 4. Restart service" 
    colorize red " 5. Remove tunnel"
    echo -e " 0. Exit"
    echo
    echo "-------------------------------"
}

# Function to read user input
read_option() {
    read -p "Enter your choice [0-5]: " choice
    case $choice in
        1) connect_mesh ;;
        2) service_status ;;
        3) view_logs ;;
		4) restart_service ;;
        5) remove_tunnel ;;
        0) exit 0 ;;
        *) echo -e "${RED} Invalid option!${NC}" && sleep 1 ;;
    esac
}

# Main script
while true
do
    display_menu
    read_option
done
