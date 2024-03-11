#!/bin/bash

#Scanning or Entering minimia ip address
function get_ip
{
	if $nmap; then
		scanning=true
		while $scanning; do
			read -p "Enter your current subnet to scan for minimia (ex.192.168.1.0/24) " subnet
			printf "Using nmap to find minimia ip address...\n"
			read result < <(nmap -sn $subnet | grep minimia)
			if echo $result; then
				read ipaddress < <(echo $result | sed -n 's/.*\(([^()]*)\).*/\1/p' | sed 's/[()]//g')
				printf "minimia hostname found!\n"
				printf "minimia ipaddress: $ipaddress\n"
				scanning=false
			else
				printf "Could not find minimia hostname!\n"
				read -p "Press Enter to Rescan"
				continue
			fi
		done
	else
		read -p "Enter minimia ip address " ipaddress
	fi
}

#Preparations
function p1_0
{
	printf "\n\nPHASE 1 Preparations\n"
	printf "	1. Remove MicroSD Card and Install in your pi\n"
	printf "	2. Connect pi to power and ethernet\n"
	printf "	3. Wait until the green led stops blinking irratically (indicating the pi has booted)\n"
	read -p "Press Enter to Continue"
	printf "\n\n"
}

#SSH into minimia and send phase1 payload
function p1_1
{
	if test -f ./.ipaddress; then
		source ./.ipaddress
	fi

	if [ -z "${ipaddress}" ]; then
		get_ip
		if [ -z "${ipaddress}" ]; then
			printf "Error reading from nmap...\n"
			read -p "Please manually enter mia's ip:" ipaddress
		fi
		touch ./.ipaddress
		echo "ipaddress=$ipaddress" > ./.ipaddress
	fi	

	printf "Connected to minimia via SSH and executing remote payload...\n"
	printf "\nDefault Root password is 'root'\n\n\n"
	ssh -o StrictHostKeyChecking=no root@$ipaddress 'bash -s' < ./packages/phase1_payload.sh
	printf "\n\nPress Enter if install finished successfully\n"
	read -p "IF INSTALL FAILED: Press Control-C Now"
	
}

#Login to mia user to setup tailscale
function p1_2
{
	if test -f ./.ipaddress; then
		source ./.ipaddress
	fi

	if [ -z "${ipaddress}" ]; then
		get_ip
		touch ./.ipaddress
		echo "ipaddress=$ipaddress" > ./.ipaddress
	fi	

	printf "\n\nLogging into minimia via SSH from default user (mia)\n"
	printf "to login into Tailscale...\n\n"
	printf "Default User password is 'mamamia'\n\n\n"
	echo mamamia | ssh -o StrictHostKeyChecking=no -tt mia@$ipaddress "sudo whoami; sudo /bin/bash -c 'echo \"* 3 * * 2 root /usr/bin/mia-tunnel/update.sh\" >> /etc/crontab' ;echo;echo;echo;echo 'Please Login to Tailscale Now:';sudo tailscale up;sudo reboot now"

	printf "\n\nPress Enter to complete install\n"
	read -p "IF INSTALL FAILED: Press Control-C Now"
}
