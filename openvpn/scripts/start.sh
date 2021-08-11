#!/bin/bash

# Configure environments
bash /root/docker_scripts/check_and_audit_baseline_config_and.sh

# Start openvpn@server service
/usr/local/sbin/openvpn --status /run/openvpn/server.status 10 --cd /etc/openvpn --config /etc/openvpn/server.conf --writepid /run/openvpn/server.pid