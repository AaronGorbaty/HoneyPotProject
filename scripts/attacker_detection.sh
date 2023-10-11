#!/bin/bash

log_file=$1
mitm_process_id=$2
prerouting_ip=$3
port_mitm_listening_on=$4
private_ip_of_container=$5
container_name=$6
recycler_script="./recycler.sh"

tail -f $log_file --pid $mitm_process_id | while read -r line; do
  # When 'tail -f' detects a new line in the file, it will enter this loop
  $recycler_script $log_file $mitm_process_id $prerouting_ip $port_mitm_listening_on $private_ip_of_container $container_name
  exit 0
done
