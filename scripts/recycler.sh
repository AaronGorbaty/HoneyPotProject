#!/bin/bash

# this IP would be pulled from the mitm log data in which the attacker is trying to connect to
ip_attacker_tried_to_connect_to="128.8.238.196"
CONTAINER_NAME=""
# System option to allow for iptables configurations
sudo sysctl -w net.ipv4.conf.all.route_localnet=1
# Generate a random number within the specified range using OpenSSL
random_hex=$(openssl rand -hex 1 | colrm 2)
# depending on the range of the first 4 bits generated by openssl we spin up an associated honeypot configuration
if [[ $random_hex == "0" || $random_hex == "1" || $random_hex == "2" || $random_hex == "3" ]]
then
  CONTAINER_NAME="control_honeypot"
  # Create and start specific container configuration, we need to add later
  sudo lxc-create -n $CONTAINER_NAME -t download -- -d ubuntu -r focal -a amd64
  sudo lxc-start -n $CONTAINER_NAME
  sleep 5
elif [[ $random_hex == "4" || $random_hex  == "5" || $random_hex == "6" || $random_hex == "7" ]]
then
  CONTAINER_NAME="HTTP_honeypot"
  # Create and start specific configuration, we need to add later
  sudo lxc-create -n $CONTAINER_NAME -t download -- -d ubuntu -r focal -a amd64
  sudo lxc-start -n $CONTAINER_NAME
  sleep 5
elif [[ $random_hex == "8" || $random_hex  == "9" || $random_hex == "a" || $random_hex == "b" ]]
then
  CONTAINER_NAME="HTTPS_honeypot"
  # Create and start specific configuration, we need to add later
  sudo lxc-create -n $CONTAINER_NAME -t download -- -d ubuntu -r focal -a amd64
  sudo lxc-start -n $CONTAINER_NAME
  sleep 5
elif [[ $random_hex == "c" || $random_hex == "d" || $random_hex == "e" || $random_hex == "f" ]]
then
  CONTAINER_NAME="SMTP_honeypot"
  # Create and start specific configuration, we need to add later
  sudo lxc-create -n $CONTAINER_NAME -t download -- -d ubuntu -r focal -a amd64
  sudo lxc-start -n $CONTAINER_NAME
  sleep 5
fi

# Install openssh and permit root login
sudo lxc-attach -n $CONTAINER_NAME -- bash -c "echo y | sudo apt install openssh-server
sed -i '/#PermitRootLogin prohibit-password/c\\PermitRootLogin yes' /etc/ssh/sshd_config
systemctl restart ssh"

# Assign container to external IP address
CONTAINER_IP=$(sudo lxc-info $CONTAINER_NAME -iH)
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $ip_attacker_tried_to_connect_to --jump DNAT --to-destination $CONTAINER_IP
  sudo iptables --table nat --insert POSTROUTING --source $ip_attacker_tried_to_connect_to --destination 0.0.0.0/0 --jump SNAT --to-source $ip_attacker_tried_to_connect_to

# Sleep for an hour, essentially giving a one hour time limit for the attacker to execute on the honeypot

# Delete the container after time limit is up
sudo iptables --table nat --delete POSTROUTING --source $CONTAINER_IP --destination 0.0.0.0/0 --jump SNAT --to-source $ip_attacker_tried_to_connect_to
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination $ip_attacker_tried_to_connect_to --jump DNAT --to-destination $CONTAINER_IP
sudo ip addr delete $ip_attacker_tried_to_connect_to/16 brd + dev eth1
sleep 1h
sudo lxc-stop -n $CONTAINER_NAME
sudo lxc-destroy -n $CONTAINER_NAME