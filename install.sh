#!/bin/bash

printf "miniMIA Install Scipt V1.0.0\n"
printf "Written by Justin 'JustinQM' O'Reilly 2024\n"


if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

#Set the final function number for both phase0 and phase1
final_phase0_function=8
final_phase1_function=2

#Checking for needed commands
if ! test -f ./.commands; then
	touch ./.commands
	printf "Checking for Commands...\n"
	printf "	Checking for nmap...\n"
	if type nmap > /dev/null; then
		printf "	nmap found\n"
		echo "nmap=true" >> ./.commands
	else
		printf "	nmap not found\n"
		echo "nmap=false" >> ./.commands
	fi

	printf "\n	Checking for bsdtar...\n"
	if type bsdtar > /dev/null; then
		printf "	bsdtar found\n"
	else
		printf "	bsdtar not found\n"
		printf "	please install bsdtar!"
		exit 
	fi

	printf "\n	Checking for tailscale...\n"
	if type tailscale > /dev/null; then
		printf "	tailscale found\n"
		echo "tailscale=true" >> ./.commands
	else
		printf "	tailscale not found\n"
		echo "tailscale=false" >> ./.commands
	fi

	printf "\n	Checking for git...\n"
	if type git > /dev/null; then
		printf "	git found\n"
	else
		printf "	git not found\n"
		printf "	please install git!"
		exit
	fi
fi

if ! test -d ./packages/mia-tunnel; then
	printf "Downloading Mia-Tunnel\n"
	git clone https://github.com/mitterdoo/mia-tunnel ./packages/mia-tunnel
	chmod -R +x ./packages/mia-tunnel
fi

if ! test -d ./packages/minimia-updater; then
	printf "Downloading minimia-updater\n"
	git clone https://github.com/JustinQM/minimia-updater ./packages/minimia-updater
	chmod -R +x ./packages/minimia-updater
fi

if ! test -f ./packages/mia-tunnel/mia_ip.txt; then
	if $tailscale; then
		mia_ipaddress=$(tailscale status | grep -w mia | awk '{print $1}')

		#ugly check
		if [ -z $mia_ipaddress ]; then
			read -p "Please Enter Mia Tailscale ipaddress:" mia_ipaddress
		fi
	else
		read -p "Please Enter Mia Tailscale ipaddress:" mia_ipaddress
	fi
	
	touch ./packages/mia-tunnel/mia_ip.txt
	echo $mia_ipaddress > ./packages/mia-tunnel/mia_ip.txt
fi

#load all of the functions
printf "Loading All Functions...\n"
source ./packages/phase0.sh
source ./packages/phase1.sh
declare -a FUNCTION
for i in $(seq 0 $final_phase0_function); do
	FUNCTION+=("p0_${i}")
done
printf "\n"
for i in $(seq 0 $final_phase1_function); do
	FUNCTION+=("p1_${i}")
done

#check if in the middle on an install
if test -f ./.checkpoint; then
	printf "\nLoading Checkpoint File...\n"
	source ./.checkpoint
else
	printf "\nCreating Checkpoint File...\n"
	touch ./.checkpoint
	echo "i=0" > ./.checkpoint
	i=0
fi

printf "\n\nStarting Install...\n"
total_functions=$(($final_phase0_function+$final_phase1_function+2))
#install
while [ "$i" -lt "$total_functions" ]; do
	${FUNCTION[$i]}
	((i+=1))
	echo "i=${i}" > ./.checkpoint
done

printf "\nInstall Complete!\n"

#Remove .commands
rm ./.commands
#Remove checkpoint
rm ./.checkpoint
#Remove cached ipaddress
rm ./.ipaddress
