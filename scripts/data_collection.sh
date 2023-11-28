#!/bin/bash

DIRECTORY=$1
FILE_NAME=$2
DIRECTORY_NAME="box_plot_data_cmds_gt_0_11-14-2023"
high_risk_commands_list=("tar" "unzip" "mv" "rm" "echo" "cp" "chmod" "mkdir" "mount" "wget" "ftp" "curl" "git clone" "lwp-download" "./" "cround" "httpd" "perl" ".pl" "passwd" "export" "PATH=" "kill" "nano" "pico" "vi" "vim" "sshd" "useradd" "userdel" "system" "sh")
medium_risk_commands_list=("w" "id" "whoami" "last" "ps" "cat/etc/*" "history" "cat .bash_history" "php -v" "uptime" "ifconfig" "uname" "cat /proc/cpuinfo" "hostnamectl")
low_risk_commands_list=("cd" "ls" "bash" "exit" "logout" "cat" "shutdown")

# Function to get the risk value of a command
get_command_risk_value() {
  local cmd=$1
  for i in "${high_risk_commands_list[@]}"; do [[ "$cmd" == *"$i"* ]] && return 3; done
  for i in "${medium_risk_commands_list[@]}"; do [[ "$cmd" == *"$i"* ]] && return 2; done
  for i in "${low_risk_commands_list[@]}"; do [[ "$cmd" == *"$i"* ]] && return 1; done
  return 0
}
# Loop through each honeypot configuration directory
echo "Directory: $DIRECTORY"
   # Loop through each log file in each directory
for FILE in "$DIRECTORY"/*
do
  # Declare arrays to store commands
  interactive_commands_array=()
  noninteractive_commands_array=()
  #echo "File: $FILE"
  num_entry_time=$(grep 'Compromising' "$FILE" | awk '{print $2}' | wc -l)
  entry_time=$(grep 'Compromising' "$FILE" | awk '{print $2}')
  num_exit_time=$(grep 'Attacker closed connection' "$FILE" | awk '{print $2}' | wc -l)
  exit_time=$(grep 'Attacker closed connection' "$FILE" | awk '{print $2}')
  num_interactive_from_reader=$(grep 'reader' "$FILE" | wc -l)
  interactive_line_from_reader=$(grep 'reader' "$FILE")
  #ATTACKER_IP=$(grep "Threshold" "$FILE" | sed -n -E 's/.* ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) .*/\1/p' | head -n 1)
  #echo "attacker ip $ATTACKER_IP"
  num_interactive_commands=0
  if [[ $num_interactive_from_reader -gt 0 ]]
  then
    while IFS= read -r interactive_line_from_reader; do
      num_commands_split_up=$(echo $interactive_line_from_reader | sed 's/;/\n/g;s/&&/\n/g;s/||/\n/g;s/\$(/\n/g;s/|/\n/g' | sed '/^\s*$/d' | wc -l) 
      IFS=$'\n' read -rd '' -a interactive_commands_array <<< $(echo $interactive_line_from_reader | sed 's/;/\n/g;s/&&/\n/g;s/||/\n/g;s/\$(/\n/g;s/|/\n/g' | awk '{$1=$1; print}')
      num_interactive_commands=$((num_interactive_commands+num_commands_split_up))
    done <<< "$interactive_line_from_reader"
  fi

  num_noninteractive_from_reader=$(grep 'Noninteractive' "$FILE" | wc -l)
  noninteractive_line_from_reader=$(grep 'Noninteractive' "$FILE")
  num_noninteractive_commands=0
  if [[ $num_noninteractive_from_reader -gt 0 ]]
  then
    while IFS= read -r noninteractive_line_from_reader; do
      num_commands_split_up=$(echo $noninteractive_line_from_reader | sed 's/;/\n/g;s/&&/\n/g;s/||/\n/g;s/\$(/\n/g;s/|/\n/g' | sed '/^\s*$/d' | wc -l)
      IFS=$'\n' read -rd '' -a noninteractive_commands_array <<< $(echo $noninteractive_line_from_reader | sed 's/;/\n/g;s/&&/\n/g;s/||/\n/g;s/\$(/\n/g;s/|/\n/g' | awk '{$1=$1; print}')
      num_noninteractive_commands=$((num_noninteractive_commands+num_commands_split_up))
    done <<< "$noninteractive_line_from_reader"
  fi

  total_risk_value=0
  for cmd in "${interactive_commands_array[@]}"; do
    get_command_risk_value "$cmd"
    total_risk_value=$((total_risk_value + $?))
  done

  for cmd in "${noninteractive_commands_array[@]}"; do
    get_command_risk_value "$cmd"
    total_risk_value=$((total_risk_value + $?))
  done

  total_num_commands=$((num_interactive_commands+num_noninteractive_commands))
  #echo "$num_interactive + $num_noninteractive = $total_num_commands"
  #echo "entry time: $entry_time \n exit time: $exit_time \n\n"
  #echo "$num_interctive_from_reader $num_interactive_commands"
  if [[ $total_num_commands -gt 0 ]]
  then
    echo "$total_risk_value $total_num_commands $FILE" >> "/home/student/data/week14/$FILE_NAME.txt"
    #echo "$total_num_commands >> "/home/student/data/$DIRECTORY_NAME/SMTP_data.txt"
  fi
done
