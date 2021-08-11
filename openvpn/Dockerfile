FROM dohuuhung1234/dohuuhung1234:debian10

# Copy all neccesary files and scripts for docker container
RUN mkdir /root/neccessary_files /root/docker_scripts /run/openvpn/ /etc/openvpn/
COPY neccessary_files/* /root/neccessary_files/
COPY scripts/* /root/docker_scripts/
RUN cp /root/docker_scripts/generate_cert_key_for_vpn_client.sh /root/docker_scripts/gen_client_file.sh && chmod a+x /root/docker_scripts/gen_client_file.sh

# Install neccessary packages
RUN apt update \
    && echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
    && apt -y install dialog apt-utils apparmor apparmor-utils grub wget vim procps build-essential libreadline-gplv2-dev libncursesw5-dev libssl-dev liblzo2-dev libpam0g-dev 2> /dev/null

# Install openvpn server 2.5.3
WORKDIR /root
RUN wget https://swupdate.openvpn.org/community/releases/openvpn-2.5.3.tar.gz \
    && tar -zxf openvpn-2.5.3.tar.gz \
    && cd openvpn-2.5.3 \
    && ./configure 2> /dev/null \
    && make 2> /dev/null \
    && make install 2> /dev/null

WORKDIR /root
RUN wget -P ~/ https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.6/EasyRSA-unix-v3.0.6.tgz \
    && tar xvf EasyRSA-unix-v3.0.6.tgz

#EXPOSE 1194

CMD ["bash", "/root/docker_scripts/start.sh"]