#!/bin/bash

high_risk_count=0
medium_risk_count=0
low_risk_count=0
total_sessions=0
interactive_commands_array=()
noninteractive_commands_array=()
attacker_ip_array=()
attacker_ip_logins_array=()
#hp_config_summary_files=()

high_risk_commands_list=("tar" "unzip" "mv" "rm" "echo" "cp" "chmod" "mkdir" "mount" "wget" "ftp" "curl" "git clone" "lwp-download" "./" "cround" "httpd" "perl" ".pl" "passwd" "export" "PATH=" "kill" "nano" "pico" "vi" "vim" "sshd" "useradd" "userdel")
medium_risk_commands_list=("w" "id" "whoami" "last" "ps" "cat/etc/*" "history" "cat .bash_history" "php -v" "uptime" "ifconfig" "uname" "cat /proc/cpuinfo")
low_risk_commands_list=("cd" "ls" "bash" "exit" "logout" "cat" "shutdown")

# Clear old versions of summary files
#: > attacker_ips.txt
#: > attacker_login_ips.txt
#: > all_attacker_commands.txt
#: > interactive_commands.txt
#: > noninteractive_commands.txt
#: > SSH_commands_summary.txt
#: > HTTP_commands_summary.txt
#: > HTTPS_commands_summary.txt
#: > SMTP_commands_summary.txt
#: > final_summary.txt
NEW_DIR="data_summary_$(date)"
mkdir "/home/student/data/$NEW_DIR/"
# Loop through each honeypot configuration directory
for DIRECTORY in /home/student/host_logs/*
do
   echo "Directory: $DIRECTORY"
   # Loop through each log file in each directory
   for FILE in "$DIRECTORY"/*
   do
      #echo "File: $FILE"

      # The command after last pipe removes leading whitespace
      interactive_commands=$(cat "$FILE" | grep reader | cut -d ':' -f 4 | sed 's/^ *//g')

      # Add interactive commands to array
      while IFS= read -r interactive_line; do
         if [ -n "$interactive_line" ]
         then
            interactive_commands_array+=("$interactive_line")
         fi
      done <<< "$interactive_commands"

      noninteractive_commands=$(cat "$FILE" | grep Noninteractive | cut -d ':' -f 4 | sed 's/^ *//g')

      # Add noninteractive commands to commands array
      while IFS= read -r noninteractive_line; do
         if [ -n "$noninteractive_line" ]
         then
            noninteractive_commands_array+=("$noninteractive_line")
         fi
      done <<< "$noninteractive_commands"

      # Number of authentications/sessions in a single log file
      num_sessions=$(cat "$FILE" | grep -c "Attacker authenticated")
      # Total up number of sessions recorded in each log file
      total_sessions=$((total_sessions+num_sessions))

      # Gets the IP addresses of attackers who attempt to sign in
      attacker_ips=$(cat "$FILE" | grep "Attacker connected" | cut -d ' ' -f 8 | sort | uniq -c)
      # Gets the IP addresses of attackers who successfully sign in
      attacker_login_ips=$(cat "$FILE" | grep "Threshold" | cut -d ' ' -f 8 | cut -d ',' -f 1)

      # Add unique IPs of attempted attackers to array
      while IFS= read -r line; do
         if [[ ! " ${attacker_ip_array[*]} " =~ ${line} ]]
         then
            attacker_ip_array+=("$line")
            echo "$line" >> "/home/student/data/$NEW_DIR/attacker_ips.txt"
         fi
      done <<< "$attacker_ips"

      # Add unique IPs of successful attackers to array
      while IFS= read -r line; do
         if [[ ! " ${attacker_ip_logins_array[*]} " =~ ${line} ]]
         then
            attacker_ip_logins_array+=("$line")
            echo "$line" >> "/home/student/data/$NEW_DIR/attacker_login_ips.txt"
         fi
      done <<< "$attacker_login_ips"

   done
done

for COMMAND in "${interactive_commands_array[@]}"
do

   # Save data about attacker commands in separate text file
   echo "$COMMAND" >> "/home/student/data/$NEW_DIR/interactive_commands.txt"
   # Use the classifications from research paper Arifianto et al.

   # If command runs a script with several commands, the execution of the script is the only command
   if [[ "$COMMAND" == *"./"* ]]
   then
      COMMAND=$(echo "$COMMAND" | cut -d ' ' -f 1)
      # echo $COMMAND
   fi

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
done

for COMMAND in "${noninteractive_commands_array[@]}"
do
   # Save data about attacker commands in separate text file
   echo "$COMMAND" >> "/home/student/data/$NEW_DIR/noninteractive_commands.txt"
   # Use the classifications from research paper Arifianto et al.

   if [[ "$COMMAND" == *"./"* ]]
   then
      COMMAND=$(echo "$COMMAND" | cut -d ' ' -f 1)
      # echo $COMMAND
   fi

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
done
# Save summary of findings in log files in separate text file

cat "/home/student/data/$NEW_DIR/interactive_commands.txt" >> "/home/student/data/$NEW_DIR/all_attacker_commands.txt"
cat "/home/student/data/$NEW_DIR/noninteractive_commands.txt" >> "/home/student/data/$NEW_DIR/all_attacker_commands.txt"

{
  echo $'\nTotal Number of Commands:' $((${#interactive_commands_array[@]} + ${#noninteractive_commands_array[@]}))
  echo "Number of Interactive Commands:" ${#interactive_commands_array[@]}
  echo "Number of Noninteractive Commands:" ${#noninteractive_commands_array[@]}
  echo "Number of Unique Attackers:" ${#attacker_ip_array[@]}
  echo "Number of Unique Attacker Sign Ins:" ${#attacker_ip_logins_array[@]}
  echo "Number of Sessions:" $total_sessions
  echo "Number of High Risk Commands:" $high_risk_count
  echo "Number of Medium Risk Commands:" $medium_risk_count
  echo "Number of Low Risk Commands:" $low_risk_count
} >> "/home/student/data/$NEW_DIR/final_summary.txt"
