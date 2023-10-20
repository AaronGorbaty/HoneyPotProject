#!/bin/bash

high_risk_count=0
medium_risk_count=0
low_risk_count=0
commands_array=()

# Loop through each honeypot configuration directory
for DIRECTORY in /home/student/host_logs/*/
do
   # Loop through each log file in each directory
   for FILE in "$DIRECTORY"/*
   do
      # The command after last pipe removes leading whitespace
      commands=$(cat "$FILE" | grep reader | cut -d ':' -f 4 | sed 's/^ *//g')
      echo "$commands"
      # Adds each line output from grep to an array
      while IFS= read -r line; do
         commands_array+=("$line")
      done <<< "$commands"
   done
done

for COMMAND in "${commands_array[@]}"
do
   # If the element in the array is not of length 0
   if [ -n "$COMMAND" ]
   then
      # echo $FILE
      echo "$COMMAND"
      # Use the rest of the classifications from research paper
      # Low risk category
      if [[ "$COMMAND" == *"exit"* ]]
      then
         low_risk_count=$((low_risk_count+1))
      # Medium risk category
      elif [[ "$COMMAND" == *"whoami"* ]]
      then
         medium_risk_count=$((medium_risk_count+1))
      # High risk category
      elif [[ "$COMMAND" == *"./"* ]]
      then
         high_risk_count=$((high_risk_count+1))
      # Do we need an else statement for commands not listed in the paper?
      fi
   fi
done

echo "Number of High Risk Commands:" $high_risk_count
echo "Number of Medium Risk Commands:" $medium_risk_count
echo "Number of Low Risk Commands:" $low_risk_count
