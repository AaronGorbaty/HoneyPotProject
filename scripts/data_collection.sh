#!/bin/bash

high_risk_count=0
medium_risk_count=0
low_risk_count=0
total_sessions=0
commands_array=()
attacker_ip_array=()

high_risk_commands_list=("tar" "unzip" "mv" "rm" "echo" "cp" "chmod" "mkdir" "mount" "wget" "ftp" "curl" "git clone" "lwp-download" "./" "cround" "httpd" "perl" "*.pl" "passwd" "export" "PATH=" "kill" "nano" "pico" "vi" "vim" "sshd" "useradd" "userdel")
medium_risk_commands_list=("w" "id" "whoami" "last" "ps" "cat/etc/*" "history" "cat .bash_history" "php -v" "uptime" "ifconfig" "uname" "cat /proc/cpuinfo")
low_risk_commands_list=("cd" "ls" "bash" "exit" "logout" "cat" "shutdown")

# Loop through each honeypot configuration directory
for DIRECTORY in /home/student/host_logs/*/
do
   echo "Directory: $DIRECTORY"
   # Loop through each log file in each directory
   for FILE in "$DIRECTORY"/*
   do
      echo "File: $FILE"
      # The command after last pipe removes leading whitespace
      commands=$(cat "$FILE" | grep reader | cut -d ':' -f 4 | sed 's/^ *//g')
      while IFS= read -r line; do
         if [ -n "$line" ]
         then
            commands_array+=("$line")
         fi
      done <<< "$commands"
      attacker_ips=$(cat "$FILE" | grep "Attacker connected" | cut -d ' ' -f 8 | sort --unique)
      num_sessions=$(cat "$FILE" | grep -c "Attacker connected")
      total_sessions=$((total_sessions+num_sessions))
      while IFS= read -r line; do
         if [[ ! " ${attacker_ip_array[*]} " =~ ${line} ]]
         then
            attacker_ip_array+=("$line")
         fi
      done <<< "$attacker_ips"
      echo "$attacker_ips"
   done
done

for COMMAND in "${commands_array[@]}"
do
   #echo "$COMMAND"
   # Use the classifications from research paper

   # Low risk category
   for LRC in "${low_risk_commands_list[@]}"
   do
      if [[ "$COMMAND" == *"$LRC"* ]]
      then
         low_risk_count=$((low_risk_count+1))
      fi
   done
   # Medium risk category
   for MRC in "${medium_risk_commands_list[@]}"
   do
      if [[ "$COMMAND" == *"$MRC"* ]]
      then
         medium_risk_count=$((medium_risk_count+1))
      fi
   done
   # High risk category
   for HRC in "${high_risk_commands_list[@]}"
   do
      if [[ "$COMMAND" == *"$HRC"* ]]
      then
         high_risk_count=$((high_risk_count+1))
      fi
   done
   # Do we need an else statement for commands not listed in the paper?
   # fi
done

echo $'\nTotal Number of Commands:' ${#commands_array[@]}
echo "Number of Attackers:" ${#attacker_ip_array[@]}
echo "Number of Sessions:" $total_sessions
echo "Number of High Risk Commands:" $high_risk_count
echo "Number of Medium Risk Commands:" $medium_risk_count
echo "Number of Low Risk Commands:" $low_risk_count

