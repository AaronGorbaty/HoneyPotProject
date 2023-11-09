#!/bin/bash

LOG_FILE="$1"
CONTAINER_NAME=$2
EXTERNAL_IP=$3
MITM_PORT=$4
RECYCLER_SCRIPT="/home/student/scripts/recycler.sh"


# Grabbing the attackers IP so that we can block all other IPs
# ATTACKER_IP=$(grep "Attacker connected:" "$LOG_FILE"| sed -n -E 's/.* ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) .*/\1/p' | head -n 1)

# While loop that does nothing (represented by ':' ) and proceeds with the rest of the script once an attacker is inside the container
while ! grep -q "Compromising the honeypot" "$LOG_FILE";
do
  sleep .5
done

# Grabbing the attackers IP so that we can block all other IPs
ATTACKER_IP=$(grep "Threshold" "$LOG_FILE" | sed -n -E 's/.* ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) .*/\1/p' | head -n 1)

# Apply appropriate firewall rules to only allow the attacker currently attacking, once the attacker gets into the container
# Limit only one session for the root user for the container, prevents two attackers from logging in at the same time
sudo lxc-attach -n $CONTAINER_NAME -- sudo ufw delete allow 'OpenSSH'
sudo lxc-attach -n $CONTAINER_NAME -- sudo ufw allow from $ATTACKER_IP to any port 22 proto tcp
sudo lxc-attach -n $CONTAINER_NAME -- sudo ufw deny 22/tcp


# Using Bash built in variable SECONDS, the while loop will run until 5 minutes is up
# Or if the grep if statement returns true, meaning the attacker exited the container
SECONDS=0
# Keep track of number of commands run, in order to track idle time
NUM_COMMANDS=0
while [[ $SECONDS -lt 600 ]];
do
  # Sleep for 30 seconds, which will be the idle time
  sleep 30
  CURR_COUNT=$(grep -E "reader|Noninteractive" "$LOG_FILE" | wc -l)
  if [[ $CURR_COUNT -ne $NUM_COMMANDS ]]; then
    # Update count of number of commands run so far
    NUM_COMMANDS=$CURR_COUNT
  else
    # This will exit out of the while loop, if the attacker has been idled for 30 seconds
    break
  fi
done

# Call the recycling script to recycle the container
$RECYCLER_SCRIPT $CONTAINER_NAME $EXTERNAL_IP $MITM_PORT &

exit 0
