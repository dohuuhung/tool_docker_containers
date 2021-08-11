#!/bin/bash

EXTEND_CONF_FILE=/root/neccessary_files/extend.conf
OPENVPN_CONF_FILE=/etc/openvpn/server.conf

if [ -f /root/openvpn_server_public_ip.txt ]; then
    echo "file exisiting"
else
    touch /root/openvpn_server_public_ip.txt
    echo "$OPENVPN_SERVER_PUBLIC_IP" >> /root/openvpn_server_public_ip.txt
fi

function check_and_change_config() {
    # INPUT:
    #   - $1: the config pattern
    #   - $2: the changed value for config
    #   - $3: configuration file absolutely path
    #   - $4: type of config syntax
    #       + 1: contain "=" symbol between key and value. E.x: a=1
    #       + 2: contain whitespace character between key and value. E.x: ssh_port 22
    #   E.x: check_and_change_config "net.ipv4.ip_forward=1" "net.ipv4.ip_forward=0" "/etc/sysctl.conf" 1
    # RETURN:
    #   - 0: change config successfully
    #   - 1: change config fail

    config_pattern=$1
    change_value=$2
    config_file_path=$3
    config_syntax_type=$4

    if [[ "$config_syntax_type" == "1" ]]; then
        check_config_existing=$(grep -E "^$config_pattern\s*=" $config_file_path)
    elif [[ "$config_syntax_type" == "2" ]]; then
        check_config_existing=$(grep -E "^$config_pattern" $config_file_path)
    else
        echo "This config syntax type has been not support in this script."
    fi

    if [[ -z "$check_config_existing" ]]; then
        echo "$change_value" >> $config_file_path
    else
        if [[ "$check_config_existing" == "$change_value" ]]; then
            echo "The config $change_value is correct."
        else
            sed -i "s/$check_config_existing/$change_value/g" $config_file_path
        fi
    fi
}

function gen_cert_key_for_openvpn_server() {
    cp /root/neccessary_files/example_vars.easyrsa /root/EasyRSA-v3.0.6/vars
    echo " " >> /root/EasyRSA-v3.0.6/vars
    echo "set_var EASYRSA_KEY_SIZE 4096" >> /root/EasyRSA-v3.0.6/vars
    cd /root/EasyRSA-v3.0.6/
    ./easyrsa init-pki
    printf 'y\n'| ./easyrsa build-ca nopass
    printf 'y\n'| ./easyrsa gen-req server nopass
    cp pki/private/server.key /etc/openvpn/
    mv pki/reqs/server.req /tmp/
    ./easyrsa import-req  /tmp/server.req server
    printf 'yes\n'| ./easyrsa sign-req server server
    cp pki/ca.crt /etc/openvpn/
    cp pki/issued/server.crt /etc/openvpn/
    ./easyrsa gen-dh
    openvpn --genkey --secret ta.key
    cp ta.key /etc/openvpn/
    cp pki/dh.pem /etc/openvpn/
}

function check_and_overwrite_config() {
    if [ -z "$OPENVPN_PORT" ]; then
        echo "No config for overwrite"
    else
        check_and_change_config "port 1194" "port $OPENVPN_PORT" $OPENVPN_CONF_FILE 2
    fi

    if [ -z "$OPENVPN_PROTOCOL" ]; then
        echo "No config for overwrite"
    else
        check_and_change_config "proto tcp" "proto $OPENVPN_PROTOCOL" $OPENVPN_CONF_FILE 2
    fi

    if [ -z "$OPENVPN_CIPHER_TYPE" ]; then
        echo "No config for overwrite"
    else
        check_and_change_config "cipher AES-256-GCM" "cipher $OPENVPN_CIPHER_TYPE" $OPENVPN_CONF_FILE 2
    fi

    if [ -z "$OPENVPN_AUTH_TYPE" ]; then
        echo "No config for overwrite"
    else
        check_and_change_config "auth SHA256" "auth $OPENVPN_AUTH_TYPE" $OPENVPN_CONF_FILE 2
    fi
}

# Configure certificate and key for openvpn server
check=$(ls -A /etc/openvpn)
if [[ ("$check" == *"ca.crt"*) && ("$check" == *"dh.pem"*) && ("$check" == *"server.crt"*) && ("$check" == *"server.key"*) && ("$check" == *"ta.key"*) ]]; then
    echo "cert and key are existing"
else
    if [ -z "$CERT_TYPE" ]; then
        gen_cert_key_for_openvpn_server
    elif [ "$CERT_TYPE" == "1" ]; then
        gen_cert_key_for_openvpn_server
    elif [ "$CERT_TYPE" == "2" ]; then
        echo "This version not support REAL certificates"
    else
        gen_cert_key_for_openvpn_server
    fi
fi

# Copy baseline server configuration
cp /root/neccessary_files/baseline_server.conf $OPENVPN_CONF_FILE
#check_and_overwrite_config





# Configure network environment
#gateway_interface=$(ip route | grep default | awk -F'dev' '{print $2}' | awk -F' ' '{print $1}')
#iptables -t nat -A POSTROUTING -s 10.8.0.0/8 -o $gateway_interface -j MASQUERADE
check_and_change_config "net.ipv4.ip_forward" "net.ipv4.ip_forward=1" /etc/sysctl.conf 1
sysctl -p

