#!/bin/bash

# wgd.sh - Copyright(C) 2021 Donald Zou [https://github.com/donaldzou]
# Under Apache-2.0 License
app_name="dashboard.py"
app_official_name="WGDashboard"
PID_FILE=./gunicorn.pid
environment=$(if [[ $ENVIRONMENT ]]; then echo $ENVIRONMENT; else echo 'develop'; fi)
if [[ $CONFIGURATION_PATH ]]; then
  cb_work_dir=$CONFIGURATION_PATH/letsencrypt/work-dir
  cb_config_dir=$CONFIGURATION_PATH/letsencrypt/config-dir
else
  cb_work_dir=/etc/letsencrypt
  cb_config_dir=/var/lib/letsencrypt
fi

dashes='------------------------------------------------------------'
equals='============================================================'
help () {
  printf "=================================================================================\n"
  printf "+          <WGDashboard> by Donald Zou - https://github.com/donaldzou           +\n"
  printf "=================================================================================\n"
  printf "| Usage: ./wgd.sh <option>                                                      |\n"
  printf "|                                                                               |\n"
  printf "| Available options:                                                            |\n"
  printf "|    start: To start WGDashboard.                                               |\n"
  printf "|    stop: To stop WGDashboard.                                                 |\n"
  printf "|    debug: To start WGDashboard in debug mode (i.e run in foreground).         |\n"
  printf "|    update: To update WGDashboard to the newest version from GitHub.           |\n"
  printf "|    install: To install WGDashboard.                                           |\n"
  printf "| Thank you for using! Your support is my motivation ;)                         |\n"
  printf "=================================================================================\n"
}

_check_and_set_venv(){
    # This function will not be using in v3.0
    # deb/ubuntu users: might need a 'apt install python3.8-venv'
    # set up the local environment
    APP_ROOT=`pwd`
    VIRTUAL_ENV="${APP_ROOT%/*}/venv"
    if [ ! -d $VIRTUAL_ENV ]; then
        python3 -m venv $VIRTUAL_ENV
    fi
    . ${VIRTUAL_ENV}/bin/activate
}



certbot_create_ssl () {
  certbot certonly --config ./certbot.ini --email "$EMAIL" --work-dir $cb_work_dir --config-dir $cb_config_dir --domain "$SERVERURL"
}

certbot_renew_ssl () {
  certbot renew --work-dir $cb_work_dir --config-dir $cb_config_dir
}

gunicorn_start () {
  printf "%s\n" "$dashes"
  printf "| Starting WGDashboard with Gunicorn in the background.    |\n"
  if [ ! -d "log" ]; then
    mkdir "log"
  fi
  d=$(date '+%Y%m%d%H%M%S')
  if [[ $USER == root ]]; then
    export PATH=$PATH:/usr/local/bin:$HOME/.local/bin
  fi
  gunicorn --access-logfile log/access_"$d".log \
  --error-logfile log/error_"$d".log 'dashboard:run_dashboard()'
  printf "| Log files is under log/                                  |\n"
  printf "%s\n" "$dashes"
}

gunicorn_stop () {
  kill $(cat ./gunicorn.pid)
}

start_wgd () {
    gunicorn_start
}

stop_wgd() {
  if test -f "$PID_FILE"; then
    gunicorn_stop
  else
    kill "$(ps aux | grep "[p]ython3 $app_name" | awk '{print $2}')"
  fi
}

start_wgd_debug() {
  printf "%s\n" "$dashes"
  printf "| Starting WGDashboard in the foreground.                  |\n"
  python3 "$app_name"
  printf "%s\n" "$dashes"
}


start_wgd () {
  echo -e "Start Dashboard--------------------------------------------------------------------------------\n"
  echo ""
  echo ""
    uwsgi --ini wg-uwsgi.ini 
  echo "--------------------------------------------------------------------------------"
}

newconf_wgd () {
  newconf_wgd0
  newconf_wgd1
  newconf_wgd2
  newconf_wgd3
  newconf_wgd4
  newconf_wgd5
}



newconf_wgd0() {
    local port_wg0=$WG_DASH_PORT_RANGE_STARTPORT
    private_key=$(wg genkey)
    public_key=$(echo "$private_key" | wg pubkey)


    cat <<EOF >"/etc/wireguard/ADMINS.conf"
[Interface]
PrivateKey = $private_key
Address = 10.0.0.1/24
ListenPort = $port_wg0
SaveConfig = true
PostUp =  /home/app/FIREWALLS/Admins/wg0-nat.sh
PreDown = /home/app/FIREWALLS/Admins/wg0-dwn.sh

EOF
    if [ ! -f "/master-key/master.conf" ]; then
        make_master_config  # Only call make_master_config if master.conf doesn't exist
    fi 
}


newconf_wgd1() {
    local port_wg1=$WG_DASH_PORT_RANGE_STARTPORT
    local port_wg1=$((port_wg1 + 1))
    private_key=$(wg genkey)
    public_key=$(echo "$private_key" | wg pubkey)

    cat <<EOF >"/etc/wireguard/MEMEBERS.conf"
[Interface]
PrivateKey = $private_key
Address = 192.168.10.1/24
ListenPort = $port_wg1
SaveConfig = true
PostUp =  /home/app/FIREWALLS/Members/wg1-nat.sh
PreDown = /home/app/FIREWALLS/Members/wg1-dwn.sh

EOF
}



newconf_wgd2() {
    local port_wg2=$WG_DASH_PORT_RANGE_STARTPORT
    local port_wg2=$((port_wg2 + 2))
    private_key=$(wg genkey)
    public_key=$(echo "$private_key" | wg pubkey)

    cat <<EOF >"/etc/wireguard/LANP2P.conf"
[Interface]
PrivateKey = $private_key
Address = 172.16.0.1/24
ListenPort = $port_wg2
SaveConfig = true
PostUp =  /home/app/FIREWALLS/LAN-only-users/wg2-nat.sh
PreDown = /home/app/FIREWALLS/LAN-only-users/wg2-dwn.sh

EOF
}

newconf_wgd3() {
    local port_wg3=$WG_DASH_PORT_RANGE_STARTPORT
    local port_wg3=$((port_wg3 + 3))
    private_key=$(wg genkey)
    public_key=$(echo "$private_key" | wg pubkey)

    cat <<EOF >"/etc/wireguard/GUESTS.conf"
[Interface]
PrivateKey = $private_key
Address = 192.168.20.1/24
ListenPort = $port_wg3
SaveConfig = true
PostUp =  /home/app/FIREWALLS/Guest/wg3-nat.sh
PreDown = /home/app/FIREWALLS/Guest/wg3-dwn.sh

EOF
}

newconf_wgd4() {
    local port_wg4=$WG_DASH_PORT_RANGE_STARTPORT
    local port_wg4=$((port_wg4 + 4))
    private_key=$(wg genkey)
    public_key=$(echo "$private_key" | wg pubkey)

    cat <<EOF >"/etc/wireguard/IPV6ADMINS.conf"
[Interface]
PrivateKey = $private_key
Address = 192.168.30.1/24
Address = 2001:db8:30:1::/64
ListenPort = $port_wg4
SaveConfig = true
PostUp =  /home/app/FIREWALLS/Guest/wg3-nat.sh
PreDown = /home/app/FIREWALLS/Guest/wg3-dwn.sh

EOF
}

newconf_wgd5() {
    local port_wg5=$WG_DASH_PORT_RANGE_STARTPORT
    local port_wg5=$((port_wg5 + 5))
    private_key=$(wg genkey)
    public_key=$(echo "$private_key" | wg pubkey)

    cat <<EOF >"/etc/wireguard/IPV6MEMBERS.conf"
[Interface]
PrivateKey = $private_key
Address = 192.168.40.1/24
Address = 2001:db8:40:1::/64
ListenPort = $port_wg5
SaveConfig = true
PostUp =  /home/app/FIREWALLS/Guest/wg3-nat.sh
PreDown = /home/app/FIREWALLS/Guest/wg3-dwn.sh

EOF
}

make_master_config() {
        local svr_config="/etc/wireguard/ADMINS.conf"
        # Check if the specified config file exists
        if [ ! -f "$svr_config" ]; then
            echo "Error: Config file $svr_config not found."
            exit 1
        fi


        #Function to generate a new peer's public key
        generate_public_key() {
            local private_key="$1"
            echo "$private_key" | wg pubkey
        }

        # Function to generate a new preshared key
        generate_preshared_key() {
            wg genpsk
        }   



    # Generate the new peer's public key, preshared key, and allowed IP
    wg_private_key=$(wg genkey)
    peer_public_key=$(generate_public_key "$wg_private_key")
    preshared_key=$(generate_preshared_key)

    # Add the peer to the WireGuard config file with the preshared key
    echo -e "\n[Peer]" >> "$svr_config"
    echo "PublicKey = $peer_public_key" >> "$svr_config"
    echo "PresharedKey = $preshared_key" >> "$svr_config"
    echo "AllowedIPs = 10.0.0.254/32" >> "$svr_config"


    server_public_key=$(grep -E '^PrivateKey' "$svr_config" | awk '{print $NF}')
    svrpublic_key=$(echo "$server_public_key" | wg pubkey)


    # Generate the client config file
    cat <<EOF >"/home/app/master-key/master.conf"
[Interface]
PrivateKey = $wg_private_key
Address = 10.0.0.254/32
DNS = 10.2.0.100,10.2.0.100
MTU = 1420

[Peer]
PublicKey = $svrpublic_key
AllowedIPs = 0.0.0.0/0
Endpoint = $WG_DASH_SERVER_IP:$WG_DASH_PORT_RANGE_STARTPORT
PersistentKeepalive = 21
PresharedKey = $preshared_key
EOF
}






if [ "$#" != 1 ];
  then
    help
  
      elif [ "$1" = "install" ]; then
        install_wgd
      elif [ "$1" = "debug" ]; then
        start_wgd_debug
      elif [ "$1" = "start" ]; then
        start_wgd
      elif [ "$1" = "newconfig" ]; then
        newconf_wgd
      else
        help
    
fi