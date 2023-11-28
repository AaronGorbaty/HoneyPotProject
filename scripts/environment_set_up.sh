#!/bin/bash

# Delete all existing containers, except for the ones that have snapshots
# We had a particular naming convention for those specific containers
containers_to_destroy=$(sudo lxc-ls --fancy | tail -n +2 | awk '{print $1}')
for container in $containers_to_destroy; do
  if ! echo $container | grep -q "Honeypot"; then
    sudo lxc-destroy -f -n $container
  fi
done

# Set up baseline firewall rules
sh /home/student/scripts/firewall_set_up.sh

# Call the 5 different instances of recycler for the 5 different IPs
# Note: sleep 30s is used to allow set up to work properly, or else too many things running at the same time, causing errors
# The first argument will be set properly in the recyler.sh script, other arguments are the proper values that we will be using
/home/student/scripts/recycler.sh "name1_doesnt_exist" "128.8.238.196" "1000" &
sleep 30s
/home/student/scripts/recycler.sh "name2_doesnt_exist" "128.8.238.28" "2000" &
sleep 30s
/home/student/scripts/recycler.sh "name3_doesnt_exist" "128.8.238.46" "3000" &
sleep 30s
/home/student/scripts/recycler.sh "name4_doesnt_exist" "128.8.238.177" "4000" &
sleep 30s
/home/student/scripts/recycler.sh "name5_doesnt_exist" "128.8.238.103" "5000" &
