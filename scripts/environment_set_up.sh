#!/bin/bash

# Delete all existing containers
containers_to_destroy=$(sudo lxc-ls --fancy | tail -n +2 | awk '{print $1}')
for container in $containers_to_destroy; do
  sudo lxc-destroy -f -n $container
done

# Set up baseline firewall rules
sh /home/student/scripts/firewall_set_up.sh

# Call the 5 different instances of recycler for the 5 different IPs
# Note sleep 5s is used to allow set up to work properly, or else too many things running at the same time, causing errors
/home/student/scripts/recycler.sh "name1_doesnt_exist" "128.8.238.196" "1000" "1234" &
sleep 5s
/home/student/scripts/recycler.sh "name2_doesnt_exist" "128.8.238.28" "2000" "1234" &
sleep 5s
/home/student/scripts/recycler.sh "name3_doesnt_exist" "128.8.238.46" "3000" "1234" &
sleep 5s
/home/student/scripts/recycler.sh "name4_doesnt_exist" "128.8.238.177" "4000" "1234" &
sleep 5s
/home/student/scripts/recycler.sh "name5_doesnt_exist" "128.8.238.103" "5000" "1234" &

echo "Set up of host environment complete."
