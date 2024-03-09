#!/bin/bash

#Checking for nmap 
printf "Checking for nmap...\n"
if type nmap > /dev/null; then
	nmap=true
	printf "nmap found\n"
else
	nmap=false
	printf "nmap not found\n"
fi

#----------------------Phase 1------------
printf "\n\nPHASE 1 Preparations\n"
printf "	1. Remove MicroSD Card and Install in your pi\n"
printf "	2. Connect pi to power and ethernet\n"
printf "	3. Wait until the green led stops blinking irratically (indicating the pi has booted)\n"
read -p "Press Enter to Continue"
printf "\n\n"

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

printf "Connected to minimia via SSH and executing remote payload...\n"
printf "\nDefault Root password is 'root'\n\n\n"
ssh -o StrictHostKeyChecking=no root@$ipaddress 'bash -s' < ./packages/phase1_payload.sh

printf "\n\nLogging into Tailscale via SSH...\n"
printf "\nDefault User password is 'mamamia'\n\n\n"
echo mamamia | ssh -o StrictHostKeyChecking=no -tt mia@$ipaddress "sudo tailscale up;sudo reboot now"

printf "\n\nInstall Complete!\n"
