#!/bin/bash

#last function number
final_mia_function=13

function check_error
{
	if [ ! "$?" -eq 0 ]; then
		printf "Error: {$?}\n"
		printf "Please re-run install script\n"
		reboot now
	fi
}

#checks if a package upgrade failed in the past.
#if so, deletes cache and regenerates keys
function pac_lock
{
	if test -f /var/lib/pacman/db.lck; then
		rm /var/lib/pacman/db.lck
		pacman -Scc --noconfirm
		mia_0 #regenerate keys in case of corruption
	fi	
}

#Create Keyring
function mia_0
{
	printf "Pacman Setup + Install and Remove Packages:\n"
	printf "	Creating and Updating Keyrings...\n"
	pacman-key --init
	pacman-key --populate archlinuxarm

	check_error
}

#Full System Update
function mia_1
{
	pac_lock
	printf "	Updating full system and mirrors...\n"
	pacman -Syu --noconfirm

	check_error
}

#Install packages from INSTALL list
function mia_2
{
	pac_lock
	if test -f /var/lib/pacman/db.lck; then
		rm /var/lib/pacman/db.lck
	fi	
	printf "	Installing all packages in install list...\n"
	while read package; do
		pacman -S $package --noconfirm
	done < ./INSTALL

	check_error
}

#Remove all packages from REMOVE list
function mia_3
{
	pac_lock
	if test -f /var/lib/pacman/db.lck; then
		rm /var/lib/pacman/db.lck
	fi	
	printf "	Removing all packages in remove list...\n"
	while read package; do
		pacman -Rs $package --noconfirm
	done < ./REMOVE

	check_error
}

#Enabling Services
function mia_4
{
	printf "\n\nConfigure Services\n"
	printf "	Enabling tailscale service...\n"
	systemctl enable tailscaled
	printf "	Enabling mia-tunnel service...\n"
	systemctl enable mia.service
	printf "	Enabling cronie service...\n"
	systemctl enable cronie.service

	check_error
}

#Downloading RPi from AUR
function mia_5
{
	if test -d /tmp/python-rpi-gpio; then
		rm -rf /tmp/python-rpi-gpio
	fi

	printf "	Installing RPi Module from AUR...\n"
	cd /tmp
	git clone https://aur.archlinux.org/python-rpi-gpio.git

	check_error
}

#Setting Permissions for folder
function mia_6
{
	chmod 777 /tmp/python-rpi-gpio
	check_error
}

#MakePKG
function mia_7
{
	cd /tmp/python-rpi-gpio
	runuser -unobody makepkg
	check_error
}

#Install Package
function mia_8
{
	pac_lock
	cd /tmp/python-rpi-gpio
	pacman -U python-rpi-gpio-0.7.1-1-any.pkg.tar.xz --noconfirm
	check_error
}

#Configure Wheel
function mia_9
{
	cd ~
	printf "	Configuring the group wheel to be able to use sudo...\n"
	echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
	check_error
}

#Create mia user
function mia_10
{
	printf "\n\nCreating and Configuring default user (mia)\n"
	printf "	Creating mia user...\n"
	useradd -m mia
	printf "	Changing mia password to default password (mamamia)\n"
	echo "mia:mamamia" | chpasswd
	printf "	Add mia user to the group wheel\n"
	usermod -aG wheel mia
	check_error
}

#Copy bashrc
function mia_11
{
	printf "	Copying bashrc to mia home directory\n"
	cp -f ./.bashrc /home/mia/.bashrc
	check_error
}

#Remove Alarm
function mia_12
{
	printf "	Removing alarm...\n"
	userdel -r alarm
	check_error
}

#Clean up
function mia_13
{
	printf "\n\nClean up and Final Configuration\n"
	printf "	Removing root SSH access...\n"
	rm /etc/ssh/sshd_config
	mv /etc/ssh/sshd_config_default /etc/ssh/sshd_config
	printf "	Changing root password to default password\n"
	echo "root:mamamia" | chpasswd
	printf "	Removing INSTALL and REMOVE lists from root\n"
	rm ./INSTALL
	rm ./REMOVE
	check_error

	printf "	Rebooting to Enable Tailscale and Mia-Tunnel Servies...\n"
	reboot now
}

#DRIVER CODE
printf "Loading Functions..."
declare -a FUNCTION
for i in $(seq 0 $final_mia_function); do
	FUNCTION+=("mia_${i}")
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
total_functions=$(($final_mia_function + 1))
#install
while [ "$i" -lt "$total_functions" ]; do
	${FUNCTION[$i]}
	((i+=1))
	echo "i=${i}" > ./.checkpoint
done
