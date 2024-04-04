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

## Analysis

Our research question influenced our decision to use the Kruskal-Wallis test, as we are trying to determine the difference in the invasiveness of commands between configurations. This is because the Kruskal-Wallis test is used to determine if there is a statistically significant difference between two or more groups of data, which, in our context, is the invasiveness of commands between the honeypot configurations. To potentially discover statistically significant differences, we looked at two separate data sets. The first dataset we examined consisted of the total number of commands run in each attacker session, while the second data set contained the invasiveness index calculated using our invasiveness scoring mechanism. We leveraged MATLAB’s statistics and machine learning toolbox to perform these statistical analyses. 

### Results

Given the statistical results, the Kruskal-Wallis test yielded a p-value of 0.3378 for invasiveness indices and a p-value of 0.259 for the numbers of commands. Both of these values exceed the standard alpha value of 0.05, so we are unable to reject our null hypothesis. 
While we failed to find statistically significant differences between our configurations, there were a number of observations worthy of additional examination. Firstly, we noticed that different attackers would frequently run similar sequences of commands as each other across all honeypot configurations. This is an indication that there are common practices that attackers use to infiltrate systems. Additionally, after recycling, we observed repeated attacks on specific IPs from the same actor. Moreover, attackers most commonly interacted with our honeypots non-interactively, running reconnaissance commands that were not considered highly invasive. This behavior indicated a preference for a quick, hit-and-run approach in reconnaissance, enabling attackers to rapidly scan through publicly accessible networks in search of vulnerable targets.

#### References
Arifianto, R. M., Sukarno, P., & Jadied, E. M. (2018). An SSH Honeypot Architecture Using Port Knocking and Intrusion Detection System. 2018 6th International Conference on Information and Communication Technology (ICoICT). https://doi.org/10.1109/ICoICT.2018.8528787
