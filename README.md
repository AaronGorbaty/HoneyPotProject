# HoneyPotProject Port-Based Analysis of Attacker Behavior: Understanding Invasiveness Across Common Services

## Summary

The purpose of this research project is to better understand both the type and the threat level of commands used by attackers based on the services or applications running on open ports. More specifically, we are looking to answer the question: how does running different services on a system affect the invasiveness of an attacker's commands? For our data collection, we identified and categorized attacker commands into three different categories: high, medium, and low risk, assigning a score for invasiveness as later described. As a result of our research, we found that there were no statistically significant differences in the invasiveness of commands between the control, HTTP, HTTPS, and SMTP honeypot configurations. 

## Experiment Design

Our experiment uses five external IPs and four different honeypot configurations: control, HTTP, HTTPS, and SMTP. For each external IP, we randomize the honeypot configuration it receives. In other words, the result of the randomization could, in some cases, result in all five external IPs having the same honeypot configuration. Through this setup, we sought to determine if there are any differences in the invasiveness of commands run by attackers between the four different honeypot configurations. 
To set up each of our honeypot configurations, we first created four base containers, each with the necessary services and configurations installed for that specific honeypot configuration. The purpose of simulating the honeypot as a container is to provide an isolated environment from the actual host system. Uncomplicated Firewall (UFW) was installed on each container in order to internally alter the container’s firewall rules, rather than controlling traffic from the outside, which would use the iptables on the host.
For all honeypots, the openssh-server was installed in order to allow attackers to connect to the honeypot. The UFW rules were then configured to allow for SSH traffic through the container’s port 22. This was the only port open for the control container. Meanwhile, the apache2 service was installed for both the HTTP and HTTPS containers. The UFW rules for the HTTP container were then configured to allow Apache on port 80, while the HTTPS container UFW rules were configured to allow Apache Secure on port 443. On containers configured with SMTP, we installed postfix, a service which sends email messages using SMTP. The UFW rules for the SMTP container were then configured to allow Postfix on port 25.
After creating all four base containers, we used the lxc-snapshot command to create snapshots for each of them, optimizing individual container recycling time. To set up every container after a reboot, the environment setup script ([environment_setup.sh](#environment_setupsh)) was executed upon reboot using crontab to call the 5 instances of the recycling script ([recycler.sh](#recyclersh)). Each instance of the recycling script first randomly assigns a configuration to the external IP passed in. After all configurations are set, the recycling script calls another script to detect attackers ([attacker_detection.sh](#attacker_detectionsh)). We also decided to use crontab to run a script ([check_stopped_processes.sh](#check_stopped_processessh)) to see if any of our MITM processes were stopped, as a result of occasional interference.

### environment_setup.sh

This script first stops and destroys any existing containers, and then sets up the base firewall rules provided by the instructors. Afterwards, five instances of the recycling script are called, each with a corresponding, distinct external IP address and MITM port argument. Between calling each instance, the sleep command was used to avoid each instance interfering with one another. 

### recycler.sh

This process is done through the use of the openssl command, which randomly generates a hex number. Based on the range that this number falls into, one of the honeypot configurations would be assigned to the IP. The container is then created by restoring the snapshots previously mentioned. NAT rules are then configured to allow for traffic to be re-routed to the intended container for the external IP, and from the container to the attacker. SSH port forwarding is also implemented using iptables NAT rules, in order to allow for SSH traffic to be recorded by the MITM server, and also to log the keystrokes and commands that are executed by the attacker. The MITM server itself, which was downloaded via GitHub, is then configured to listen on a specific MITM port (specified as an argument passed in) for the corresponding container created earlier. 

### attacker_detection.sh 

The attacker detection script is responsible for controlling how long the attacker stays in the container before it is recycled by keeping track of attacker idle time. The attacker detection script continually inspects the MITM log associated with the container, waiting until an attacker connects and logs into the honeypot. The MITM server’s auto-access feature allows an attacker to log into the container after one attempt with any password. The feature is then disabled after being used once, preventing other attackers from connecting to the honeypot. Once the attacker logs in, the script sets up the appropriate firewall rules to prohibit other attackers from logging into the honeypot too. These firewall rules address a specific flaw with the MITM server: if an attacker logs in with the same credentials as the first auto-access user, they will be able to log in. Therefore, we needed to add additional rules that would only allow traffic from the attacker currently logged into the container, blocking all traffic from any other IP. After the firewall rules are set, the script then continuously checks the log to see if an attacker has been idle for more than 30 seconds, or if the max time limit of 10 minutes is reached. If either of those conditions are met, the container is then recycled by calling the recycling script again. The recycling script then deletes the honeypot associated with the external IP, including the corresponding NAT rules and MITM process, and then restarts the whole container setup process again by randomly assigning one of the four honeypot configurations to the IP. 

### check_stopped_processes.sh

 This script saved us a lot of time, eliminating the need to manually check to see if any problems occurred, and allowing us to collect more data.  All scripts were backed up to GitHub, giving us the ability to reference previous versions, and maintain a copy in case our scripts were deleted or lost. All log files were stored on the host virtual machine, in a directory called host_logs, and separated based on configuration: control, HTTP, HTTPS, and SMTP. All of the logs were also backed up to our personal computers, which we then uploaded to our shared Google Drive folder.

### data_collection.sh

This script takes in two arguments. The first argument is the directory path of a specified honeypot configuration, and the second argument is the name of the honeypot configuration. The script went through every log file in a honeypot configuration specified by the first argument, calculated a numerical “invasiveness index” metric based on all of the commands that were ran, retrieved the number of commands typed in each log file, and printed those two metrics along with the name of the log file to standard output. Finally, that output was redirected to a text file using the name provided in the second argument.

## Data Collection

We collected the number of commands that attackers ran, and a measurement of their overall invasiveness during each attacker session. The data was collected from the log files generated by the MITM server. In total, our experiment yielded 61,956 log files, or a little under 15,500 log files for each of the four honeypot configurations. However, some of these log files did not have any commands logged, and were therefore excluded in data analysis. We excluded the log files that did not have any commands logged because we wanted to disregard sessions that had no level of invasiveness. In total, we eliminated 15,857 log files, or approximately 4,000 log files per honeypot configuration for the aforementioned reason.
We processed the data using a data collection script ((data_collection.sh)[#data_collection.sh]). 

### Data Categorization

To calculate this invasiveness index, we first categorized different standard Linux commands into one of three groups. These three groups were labeled as low risk commands, medium risk commands, and high risk commands, following the research published by Arifianto et al. (2018) Later, we categorized commands that were not classified in the original research paper by Arifianto et al. (2018) by extrapolating their definitions of low, medium, and high risk commands.

#### Classification model created by Arifianto et al. (2018)

| Category  | Weight | Command                                             |
|-----------|--------|-----------------------------------------------------|
| High Risk | 3      | tar, unzip, mv, rm, echo, cp, chmod, mkdir, mount, wget, ftp, curl, git clone, lwp-download, ./, crond, httpd, perl\*, pl, passwd, export, PATH=, kill, nano, pico, vi, vim, ssh, useradd, userdel |
| Medium Risk | 2      | w, id, whoami, last, ps, cat/etc/*, history, cat .bash_history, php -v, uptime, ifconfig, uname, cat /proc/cpuinfo |
| Low Risk  | 1      | cd, ls, bash, exit, logout, cat, shutdown           |

#### New commands classified by our group

| Category  | Weight | Command  |
|-----------|--------|----------|
| High Risk | 3      | sh, system|
| Medium Risk | 2      | hostnamectl |
| Low Risk  | 1      | (n/a)    |

### Score Calculation

The index begins at zero and gets incremented by one for every low risk command, two for every medium risk command, and three for every high risk command. Before calculating the invasiveness index for each attacker session, we split up and counted commands that were separated by a semicolon, logical ‘AND’ operator, or logical ‘OR’ operator. If an attacker typed in multiple commands in a single line, we did not want the first command to be the only command with the invasiveness score measured.	We decided on this scoring system so that the invasiveness index for a session would increase if there were more commands typed during a single attacker session, or if commands were classified at a higher level of risk. However, we noticed some limitations with our scoring system as well. For example, two attackers could theoretically accomplish the same task but with two different sets of commands, and thus end up with different invasiveness scores. We also brainstormed other ways to measure the invasiveness of commands in each log file, which included calculating the mean or median of all of the invasiveness scores for the log files in each honeypot configuration. We decided against using the mean or median as the method to calculate the invasiveness score of a single attacker session because we believe that the invasiveness index should always increase with the number of commands run by an attacker.  

### Analysis

Our research question influenced our decision to use the Kruskal-Wallis test, as we are trying to determine the difference in the invasiveness of commands between configurations. This is because the Kruskal-Wallis test is used to determine if there is a statistically significant difference between two or more groups of data, which, in our context, is the invasiveness of commands between the honeypot configurations. To potentially discover statistically significant differences, we looked at two separate data sets. The first dataset we examined consisted of the total number of commands run in each attacker session, while the second data set contained the invasiveness index  calculated using our invasiveness scoring mechanism (Section 6). We leveraged MATLAB’s statistics and machine learning toolbox to perform these statistical analyses.
Given the statistical results (see Appendix B), the Kruskal-Wallis test yielded a p-value of 0.3378 for invasiveness indices and a p-value of 0.259 for the numbers of commands. Both of these values exceed the standard alpha value of 0.05, so we are unable to reject our null hypothesis. 
While we failed to find statistically significant differences between our configurations, there were a number of observations worthy of additional examination. Firstly, we noticed that different attackers would frequently run similar sequences of commands as each other across all honeypot configurations. This is an indication that there are common practices that attackers use to infiltrate systems. Additionally, after recycling, we observed repeated attacks on specific IPs from the same actor. Moreover, attackers most commonly interacted with our honeypots non-interactively, running reconnaissance commands that were not considered highly invasive. This behavior indicated a preference for a quick, hit-and-run approach in reconnaissance, enabling attackers to rapidly scan through publicly accessible networks in search of vulnerable targets.
8. Conclusion
Although we are unable to reject the null hypothesis, our findings could still provide useful information for system administrators. For example, it may still be useful to know from an operational security perspective that opened ports on a machine do not affect the invasiveness of commands run by attackers. If we could continue our project, however, we would seek to explore whether or not the invasiveness of attacker commands might differ when looking at less frequently used ports. HTTP, HTTPS, and SMTP are extremely common protocols and may attract a broader spectrum of attacks. We would like to identify if there are any more advanced or specialized sequences of attacker commands against machines running more niche services. We would also continue our research by adding more independent variables of different honeypot configurations in order to simulate a more realistic system, since each honeypot only had a maximum of two ports open in our research. 
We are also interested in analyzing if the number of attempted attacker connections changes based on the services running or ports open on a machine. While our research accounted for the number and invasiveness of commands, our experimental design was not conducive for observing whether or not the number of attempted connections would significantly change between honeypot configurations. This could provide additional information for system administrators regarding whether or not they should prioritize closing ports that might not be necessary for their operational purposes. If having more ports open attracts more connections, then it would be in their best interest to keep as few open as possible. This experiment would be possible to conduct based on our current knowledge and the architecture used throughout our research. We would be able to leverage our existing honeypot configurations, simply disabling auto-access and denying all attacker connections. This would allow us to easily count the number of attempted connections via the MITM logs.

References
Arifianto, R. M., Sukarno, P., & Jadied, E. M. (2018). An SSH Honeypot Architecture Using Port Knocking and Intrusion Detection System. 2018 6th International Conference on Information and Communication Technology (ICoICT). https://doi.org/10.1109/ICoICT.2018.8528787
Fan, W., Du, Z., Fernández, D., & Villagrá, V. (2018). Enabling an Anatomic View to Investigate Honeypot Systems: A Survey. IEEE Systems Journal, 12(4), 3906-3919. https://doi.org/10.1109/JSYST.2017.2762161
Internet Assigned Numbers Authority. (2023, September 12). Service name and Transport Protocol Port Number Registry. https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml 
Ramsbrock, D., Berthier, R., & Cukier, M. (2007). Profiling Attacker Behavior Following SSH Compromises. 37th Annual IEEE/IFIP International Conference on Dependable Systems and Networks. https://doi.org/10.1109/DSN.2007.76
Winkelman, R. (2013). What is a Protocol? Florida Center for Instructional Technology. https://fcit.usf.edu/network/chap2/chap2.htm 
Zobal, L., Kolář, D., & Fujdiak, R. (2019). Current State of Honeypots and Deception Strategies in Cybersecurity. 2019 11th International Congress on Ultra Modern Telecommunications and Control Systems and Workshops. https://doi.org/10.1109/ICUMT48472.2019.8970921
Appendix A
Project Takeaways
Throughout our project, we learned the importance of documenting iterative development. Sometimes, we attempted to make changes to our scripts that inadvertently broke existing functionalities. Since we did not have consistent back-ups, we were not easily able to return to our last working version. Towards the end of our project, we improved in this area by more consistently pushing our changes to GitHub and utilizing the pull request system.
With regard to the attackers, we did not come across anything surprising or interesting as most of the activity we observed on our honeypots seemed to be produced by bots with predictable and repetitive behaviors. Initially, we found that some project guidelines such as randomization and data collection procedures were unclear, but we found that stand-ups provided a useful time to share our progress and receive specific corrective feedback from instructors, which helped resolve these issues.
Lastly, throughout the experiment, we discovered failures within our design which hindered our ability to efficiently collect data. Most notably, we did not implement snapshots as a mechanism for recycling our containers until later in the project. Following our design resolution to implement snapshots of our honeypots on November 9th, we noticed that the quantity of data we collected increased significantly, as our recycling duration for each honeypot decreased from five minutes to one minute.
 



Appendix B
Experimental Data
 
Figure B.1: 
Kruskal-Wallis test on invasiveness scores


Figure B.2: 
Kruskal-Wallis test on number of commands


Figure B.3: 
A sample of the data representing the invasiveness score of an attacker session
Honeypot_Data-11-30-23.xlsx

Figure B.4: 
A sample of the data representing the number of commands run per attacker session
Honeypot_Data-11-30-23.xlsx



Category
Weight
Command
High Risk
3
tar, unzip, mv, rm, echo, cp, chmod, mkdir, mount, wget, ftp, curl, git clone, lwp-download, ./, cround, httpd, perl, *.pl, passwd, export, PATH=, kill, nano, pico, vi, vim, sshd, useradd, userdel
Medium Risk
2
w, id, whoami, last, ps, cat/etc/*, history, cat .bash_history, php -v, uptime, ifconfig, uname, cat /proc/cpuinfo
Low Risk
1
cd, ls, bash, exit, logout, cat, shutdown


Figure B.5A
Classification model created by Arifianto et al. (2018)

Category
Weight
Command
High Risk
3
sh, system
Medium Risk
2
hostnamectl
Low Risk
1
(n/a)


Figure B.5B
New commands classified by our group
Appendix C
Honeypot Scripts
environment_setup.sh
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

recycler.sh
#!/bin/bash

# Just in case, if we had accidentally passed in the wrong number of arguments, display usage statement
if [ $# -ne 3 ]; then
  echo "usage: $0 <container_name external_IP_address mitm_port>"
  exit 1
fi

# Note: For assigning a new configuration for the IP, we will pass in a random string for the CONTAINER_NAME argument
CONTAINER_NAME=$1
EXTERNAL_IP=$2
MITM_PORT=$3
DIRECTORY_NAME=""

if [ -z $(sudo lxc-ls "$CONTAINER_NAME") ]; then # If container does not exist...

  # Generate a random number within the specified range using OpenSSL
  random_hex=$(openssl rand -hex 1 | colrm 2)

  # The following if statements are used to randomly assign a configuration to the IP address:
  # Depending on the hex number generated by openssl we spin up the associated honeypot configuration
  if [[ $random_hex == "0" || $random_hex == "1" || $random_hex == "2" || $random_hex == "3" ]]
  then
    # Set the container name and directory name for where container log will be stored
    CONTAINER_NAME="SSH_$EXTERNAL_IP"
    DIRECTORY_NAME="control_honeypot"

    # Restore SSH Honeypot using snapshot
    # Note: snapshot already has openSSH installed
    # sleep command is to give container some time to start up
    sudo lxc-snapshot -n SSH_Honeypot -r snap0 -N $CONTAINER_NAME
    sudo lxc-start -n $CONTAINER_NAME
    sleep 6

  elif [[ $random_hex == "4" || $random_hex  == "5" || $random_hex == "6" || $random_hex == "7" ]]
  then
    # Set the container name and directory name for where container log will be stored
    CONTAINER_NAME="HTTP_$EXTERNAL_IP"
    DIRECTORY_NAME="HTTP_honeypot"

    # Restore HTTP Honeypot using snapshot
    # Note: snapshot has openSSH and Apache Server installed
    # sleep command is to give container some time to start up
    sudo lxc-snapshot -n HTTP_Honeypot -r snap0 -N $CONTAINER_NAME
    sudo lxc-start -n $CONTAINER_NAME
    sleep 6

  elif [[ $random_hex == "8" || $random_hex  == "9" || $random_hex == "a" || $random_hex == "b" ]]
  then
    # Set the container name and directory name for where container log will be stored
    CONTAINER_NAME="HTTPS_$EXTERNAL_IP"
    DIRECTORY_NAME="HTTPS_honeypot"

    # Restore HTTPS Honeypot using snapshot
    # Note: snapshot has openSSH and Apache Secure installed
    # sleep command is to give container some time to start up
    sudo lxc-snapshot -n HTTPS_Honeypot -r snap0 -N $CONTAINER_NAME
    sudo lxc-start -n $CONTAINER_NAME
    sleep 6

  elif [[ $random_hex == "c" || $random_hex == "d" || $random_hex == "e" || $random_hex == "f" ]]
  then
    # Set the container name and directory name for where container log will be stored
    CONTAINER_NAME="SMTP_$EXTERNAL_IP"
    DIRECTORY_NAME="SMTP_honeypot"

    # Restore SMTP Honeypot using snapshot
    # Note: snapshot has openSSH and postfix server installed
    # sleep command is to give container some time to start up
    sudo lxc-snapshot -n SMTP_Honeypot -r snap0 -N $CONTAINER_NAME
    sudo lxc-start -n $CONTAINER_NAME
    sleep 6

  fi

  # Assign container to external IP address, through pre-routing and post-routing rules
  sudo sysctl -w net.ipv4.conf.all.route_localnet=1
  CONTAINER_IP=$(sudo lxc-info $CONTAINER_NAME -iH)
  # If statement is used just in case if CONTAINER_IP is an empty string, a problem that occurs occasionally
  if [ -z "$CONTAINER_IP" ]; then
    sleep 5
    CONTAINER_IP=$(sudo lxc-info $CONTAINER_NAME -iH)
  fi
  sudo ip addr add $EXTERNAL_IP/24 brd + dev eth1
  sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $EXTERNAL_IP --jump DNAT --to-destination $CONTAINER_IP
  sudo iptables --table nat --insert POSTROUTING --source $CONTAINER_IP --destination 0.0.0.0/0 --jump SNAT --to-source $EXTERNAL_IP
  
  # Port forwarding ssh traffic to MITM and other routing rules
  sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination $EXTERNAL_IP --protocol tcp --dport 22 --jump DNAT --to-destination 10.0.3.1:$MITM_PORT

  # Start MITM server, running the forever command to be listening on a specific port
  # LOG_FILE variable is used to set the name of our log file
  LOG_FILE="$CONTAINER_NAME.log -> $(date)"
  sudo forever -l /home/student/host_logs/$DIRECTORY_NAME/"$LOG_FILE" -a start --uid "mitm_id_$CONTAINER_NAME" /home/student/MITM/mitm.js -n $CONTAINER_NAME -i $CONTAINER_IP -p $MITM_PORT --auto-access --auto-access-fixed 1 --debug --mitm-ip 10.0.3.1

  # Call attacker detection script with the necessary arguments
  /home/student/scripts/attacker_detection.sh /home/student/host_logs/$DIRECTORY_NAME/"$LOG_FILE" $CONTAINER_NAME $EXTERNAL_IP $MITM_PORT &

else
  # Attacker detection script triggers this section when it is time to recycle the container, beginning with deleting the existing one first
  # If container already exists delete container and iptables rules
  CONTAINER_IP=$(sudo lxc-info $CONTAINER_NAME -iH)
  # Once again, if statement to double check if CONTAINER_IP is empty string, as it is a problem that occurs occasionally
  if [ -z "$CONTAINER_IP" ]; then
    sleep 5
    CONTAINER_IP=$(sudo lxc-info $CONTAINER_NAME -iH)
  fi
  sudo ip addr delete $EXTERNAL_IP/24 brd + dev eth1
  sudo iptables --table nat --delete POSTROUTING --source $CONTAINER_IP --destination 0.0.0.0/0 --jump SNAT --to-source $EXTERNAL_IP
  sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination $EXTERNAL_IP --jump DNAT --to-destination $CONTAINER_IP
  sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination $EXTERNAL_IP --protocol tcp --dport 22 --jump DNAT --to-destination 10.0.3.1:$MITM_PORT

  # Stop the MITM instance for the container
  sudo forever stop "mitm_id_$CONTAINER_NAME"

  # Stop the container and destroy it, -f argument forces container to be destroyed even if running
  sudo lxc-destroy -f -n $CONTAINER_NAME

  # Call the recycling script again for the same IP to create another container, arguments don't matter as they will be set properly later
  /home/student/scripts/recycler.sh "temp" $EXTERNAL_IP $MITM_PORT &

fi




attacker_detection.sh
#!/bin/bash

# Variables to be used, were passed in by recycler.sh
LOG_FILE="$1"
CONTAINER_NAME=$2
EXTERNAL_IP=$3
MITM_PORT=$4
RECYCLER_SCRIPT="/home/student/scripts/recycler.sh"


# While loop that waits for an attacker to connect and login to the container
# sleep command is used so while loop won't run so quickly and cause system issues
while ! grep -q "Compromising the honeypot" "$LOG_FILE";
do
  sleep .5
done

# Grabbing the attackers IP so that we can block all other IPs later (described below)
ATTACKER_IP=$(grep "Threshold" "$LOG_FILE" | sed -n -E 's/.*Attacker: ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+),.*/\1/p')

# Apply appropriate firewall rules to only allow the attacker currently attacking, once the attacker gets into the container
# Prevents two attackers from logging in at the same time
sudo lxc-attach -n $CONTAINER_NAME -- sudo ufw delete allow 'OpenSSH'
sudo lxc-attach -n $CONTAINER_NAME -- sudo ufw allow from $ATTACKER_IP to any port 22 proto tcp
sudo lxc-attach -n $CONTAINER_NAME -- sudo ufw deny 22/tcp

# Using Bash built in variable
SECONDS=0
# Keep track of number of commands run, in order to track idle time
NUM_COMMANDS=0
# Using Bash built in variable SECONDS, the while loop will run until 10 minutes is up
# Or if an attacker has been idle for more than 30 seconds, which means no commands run
while [[ $SECONDS -lt 600 ]];
do
  # Sleep for 30 seconds, which will be the idle time
  sleep 30
  # Count the number of commands run
  CURR_COUNT=$(grep -E "reader|Noninteractive" "$LOG_FILE" | wc -l)
  # If the number of commands run has changed...
  if [[ $CURR_COUNT -ne $NUM_COMMANDS ]]; then
    # Update count of number of commands run so far
    NUM_COMMANDS=$CURR_COUNT
  else
    # This will exit out of the while loop, if the attacker has been idled for 30 seconds
    # number of commands is the same
    break
  fi
done

# Call the recycling script to recycle the container
$RECYCLER_SCRIPT $CONTAINER_NAME $EXTERNAL_IP $MITM_PORT &

exit 0

check_stopped_processes.sh

#!/bin/bash

# Script is responsible for checking if any forever processes have been stopped
# If so, it will then reboot the system, so that we don't have to do it ourselves
# Sometimes, processes are just stopped for a number of reasons at random times

STOPPED=$(sudo forever list 2>/dev/null | grep "STOPPED")

# If string isn't empty
if [[ -n "$STOPPED" ]]; then
  sudo reboot
fi

data_collection.sh
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
  num_entry_time=$(grep 'Compromising' "$FILE" | awk '{print $2}' | wc -l)
  entry_time=$(grep 'Compromising' "$FILE" | awk '{print $2}')
  num_exit_time=$(grep 'Attacker closed connection' "$FILE" | awk '{print $2}' | wc -l)
  exit_time=$(grep 'Attacker closed connection' "$FILE" | awk '{print $2}')
  num_interactive_from_reader=$(grep 'reader' "$FILE" | wc -l)
  interactive_line_from_reader=$(grep 'reader' "$FILE")
  #ATTACKER_IP=$(grep "Threshold" "$FILE" | sed -n -E 's/.* ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) .*/\1/p' | head -n 1)
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
  if [[ $total_num_commands -gt 0 ]]
  then
    echo "$total_risk_value $total_num_commands $FILE" >> "/home/student/data/week14/$FILE_NAME.txt"
  fi
done





