#!/bin/bash

log_file="$1"
container_name=$2
external_ip=$3
mitm_port=$4
recycler_script="/home/student/scripts/recycler.sh"

echo "Sleeping for 5 seconds..."
sleep 5s

tail -f -n 0 "$log_file" | while read -r line; do
  # When 'tail -f' detects a new line in the file, it will enter this loop
  echo triggered
  #grabbing the attackers IP so that we can block all other IPs
  attacker_ip=$(grep "Attacker connected:" "$log_file"| sed -n -E 's/.* ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) .*/\1/p' | head -n 1)
  if tail -f -n 1 "$log_file" | grep -q "Attacker authenticated and is inside container"; then
    $recycler_script $container_name $external_ip $mitm_port $attacker_ip &
  fi
  exit 0
done
