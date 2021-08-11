#!/bin/bash

CLIENT_CONFIG_DIR=/root/client-configs
CLIENT_CONFIG_KEY_DIR=/root/client-configs/keys
CLIENT_FILE_DIR=/root/client-configs/files

if [ -d $CLIENT_CONFIG_KEY_DIR ]; then
    echo The client config directory existing
else
    mkdir -p $CLIENT_CONFIG_KEY_DIR
    chmod -R 700 $CLIENT_CONFIG_KEY_DIR
fi

if [ -f $CLIENT_CONFIG_DIR/base.conf ]; then
    echo "Client config base file existing"
else
    cp /root/neccessary_files/client_base_config.conf $CLIENT_CONFIG_DIR/base.conf
fi

if [ -d $CLIENT_FILE_DIR ]; then
    echo The client file directory existing
else
    mkdir -p $CLIENT_FILE_DIR
fi

if [ -f $CLIENT_CONFIG_DIR/make_config.sh ]; then
    echo "Client config base file existing"
else
    cp /root/neccessary_files/make_config.sh $CLIENT_CONFIG_DIR/make_config.sh
    chmod 700 $CLIENT_CONFIG_DIR/make_config.sh
fi

CLIENT_NAME=$1
cml_vpn_ip=$2
cml_vpn_port=$3
os_type=$4
CLIENT_KEY_FILE_NAME="$CLIENT_NAME"".key"
CLIENT_REQ_FILE_NAME="$CLIENT_NAME"".req"
CLIENT_CRT_FILE_NAME="$CLIENT_NAME"".crt"
VPN_SERVER_PUBLIC_IP=$(cat /root/openvpn_server_public_ip.txt)
VPN_PORT=$(cat /etc/openvpn/server.conf | grep port | awk '{print $2}')
VPN_PROTOCOL=$(cat /etc/openvpn/server.conf | grep proto | awk '{print $2}')
VPN_CIPHER=$(cat /etc/openvpn/server.conf | grep cipher | awk '{print $2}')
VPN_AUTH=$(cat /etc/openvpn/server.conf | grep auth | egrep -v "tls-auth" | awk '{print $2}')

if [[ -z "$cml_vpn_ip" ]]; then
    echo "nothing"
else
    VPN_SERVER_PUBLIC_IP=$cml_vpn_ip
fi

if [[ -z "$cml_vpn_port" ]]; then
    echo "nothing"
else
    VPN_PORT=$cml_vpn_port
fi

cd /root/EasyRSA-v3.0.6/
printf 'y\n'| ./easyrsa gen-req $CLIENT_NAME nopass
cp pki/private/$CLIENT_KEY_FILE_NAME $CLIENT_CONFIG_KEY_DIR
mv pki/reqs/$CLIENT_REQ_FILE_NAME /tmp/
./easyrsa import-req /tmp/$CLIENT_REQ_FILE_NAME $CLIENT_NAME
printf 'yes\n'| ./easyrsa sign-req client $CLIENT_NAME
cp pki/issued/$CLIENT_CRT_FILE_NAME $CLIENT_CONFIG_KEY_DIR
cp /etc/openvpn/ca.crt $CLIENT_CONFIG_KEY_DIR
cp /etc/openvpn/ta.key $CLIENT_CONFIG_KEY_DIR


sed -i "s/proto PROTOCOL/proto $VPN_PROTOCOL/g" $CLIENT_CONFIG_DIR/base.conf
sed -i "s/remote PUBLIC_IP_PORT/remote $VPN_SERVER_PUBLIC_IP $VPN_PORT/g" $CLIENT_CONFIG_DIR/base.conf
sed -i "s/cipher CIPHER/cipher $VPN_CIPHER/g" $CLIENT_CONFIG_DIR/base.conf
sed -i "s/auth AUTH/auth $VPN_AUTH/g" $CLIENT_CONFIG_DIR/base.conf

if [[ -z "$os_type" ]]; then
    echo "You must provide OS type for script to create vpn client config file."
else
    if  [[ "$os_type" == "window" ]]; then
        echo "There is nothing to do for Window"
    elif [[ "$os_type" == "linux" ]]; then
        echo " " >> $CLIENT_CONFIG_DIR/base.conf
        echo "up /etc/openvpn/update-resolv-conf" >> $CLIENT_CONFIG_DIR/base.conf
        echo " " >> $CLIENT_CONFIG_DIR/base.conf
        echo "down /etc/openvpn/update-resolv-conf" >> $CLIENT_CONFIG_DIR/base.conf
    else
        echo "This OS_TYPE not support by the script."
    fi
fi

cd $CLIENT_CONFIG_DIR
./make_config.sh $CLIENT_NAME

