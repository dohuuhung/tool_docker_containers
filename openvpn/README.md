# GUIDE TO GET OPENVPN_SERVER CONTAINER

## 1. Prerequiresites
Before install or setup anything, let ensure that your host visit those following requirements:

    - Docker Engine installed
    - Docker Compose installed

At the moment this document was wrote, version of these packages are:

    - Docker Engine: 20.10.7
    - Docker Compose: 1.29.2

## 2. Build Docker image for openvpn server
Run the following command to build docker images for openvpn_server version 2.5.3:

`$ docker build -t <DOCKER_REPO>:<IMAGE_TAG> .`

E.x: docker build -t dohuuhung1234/dohuuhung1234:openvpnserver_2.5.3 .

## 3. Preconfiguration before start docker

In the file **.env**, chose value for 2 fields DOCKER_REPO & IMAGE_TAG suite for you:

`E.x: DOCKER_REPO=dohuuhung1234/dohuuhung1234
      IMAGE_TAG=openvpnserver_2.5.3`

In the file **openvpn.env**, user must configure for field **OPENVPN_SERVER_PUBLIC_IP**. This configuration field is used to indicate the public IP which client will communicate to create vpn tunnel:

`E.x: OPENVPN_SERVER_PUBLIC_IP=192.168.1.110`

If you want prepare configuration for openvpn server process, you can do with the file **neccessary_files/baseline_server.conf**. This file will be wrote to **/etc/openvpn/server.conf** inside container and used for openvpn server process.

Before running openvpn container, user must run the following command to configure network environment:

```
$ gateway_interface=$(ip route | grep default | awk -F'dev' '{print $2}' | awk -F' ' '{print $1}')
$ iptables -t nat -A POSTROUTING -s 10.8.0.0/8 -o $gateway_interface -j MASQUERADE
```

Sure the config field "net.ipv4.ip_forward" has value "1" (net.ipv4.ip_forward=1) in file /etc/sysctl.conf, and run command:

`$ sysctl -p`

## 4. RUN DOCKER CONTAINER
We will use docker-compose command to run docker container for openvpn server:

`$ docker-compose up -d`

When you want change configuration for openvpn server (config in file neccessary_files/baseline_server.conf), just modify config and then run 2 command:'

```
$ docker-compose down
$ docker-compose up -d
```

## 5. Generate client config file
To generate config file for client which create vpn connection with openvpn server. Use the following command in the host running container:

```
$ docker exec -ti openvpn_server bash /root/docker_scripts/gen_client_file.sh <client_name> <tunnel_vpn_ip> <vpn_port> <os_type>
OR
$ docker exec -ti openvpn_server bash /root/docker_scripts/gen_client_file.sh <client_name> <vpn_domain_name> <vpn_port> <os_type>
```

In that:

      - <client_name>: name of vpn client
      - <tunnel_vpn_ip>: IP address which client communicate to for creating vpn tunnel. IP can be located on Openvpn server or on a Nginx revese proxy
      - <vpn_domain_name>: domain name which provide vpn service. This domain name will be resolved to IP address which can communicate for use vpn service
      - <vpn_port>: the port used to create vpn tunnel
      - <os_type>: OS of client machine. Now script is just supporting for 2 types: linux and window

E.x: docker exec -ti openvpn_server bash /root/docker_scripts/gen_client_file.sh client_1 107.120.80.100 1194

And then, the client config file client_1.opvn will create in the directory **client_files**. Just securely send it to the client machine, and client will use that config file to connect to openvpn server.

## 6. Configure Openvpn server behind Nginx Reverse proxy
We can deploy Openvpn server for working after a Nginx reverse proxy.
To gain this target, use don't need to configure anything in the openvpn server side.

Every configuration will be handle in the nginx server.

This config line should be enable in the file /etc/sysctl.conf: `net.ipv4.ip_nonlocal_bind=1`.  Write it to file /etc/sysctl.conf and after run this command: `$ sysctl -p`

If using Nginx Proxy Manager docker don't forget that the conf below will be needed to be added under nginx custom configuration when adding your proxy host.

Use the below example config file /etc/nginx/nginx.conf to enable tcp proxy for openvpn server:
```
load_module /usr/lib/nginx/modules/ngx_stream_module.so;

worker_processes  1;

events {
    worker_connections  1024; 
}

stream{
    upstream backend{
        hash $remote_addr consistent;

        server <openvpn_server_ip>:<vpn_port>;
    }

    server {
        listen [<vpn_ip>:]<listen_port> so_keepalive=on;
        # E.x: listen 192.168.1.34:1199 so_keepalive=on;
        server_name  <domain_name_for_vpn_service>;
        # E.x: server_name  vpn1.example.com;
        proxy_connect_timeout 300s;
        proxy_timeout 300s;
        proxy_pass backend;
    }
}
```
Sure that we have first line in file nginx.conf:
`load_module /usr/lib/nginx/modules/ngx_stream_module.so;`

After that we use section "stream" to configure tcp proxy module of nginx.

In that:

      -  <openvpn_server_ip>: the IP address of openvpn server which the nginx server will communicate to create vpn tunnel
      -  <vpn_port>: the port used by openvpn server for vpn tunnel. E.x: 1194
      -  <vpn_ip>: the IP address, which client will communicate to for using vpn service. This is the option.
      -  <listen_port>: port which nginx server listen
      -  <domain_name_for_vpn_service>: the domain name which used for vpn service. This domain will be resolved to external IP of nginx server

After having the correct configuration, run the following commands to restart nginx service:

```
$ nginx -t
$ systemctl restart nginx
```