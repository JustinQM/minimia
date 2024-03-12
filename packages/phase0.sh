#!/bin/bash

#Preparations Listing
function p0_0
{
	printf "PHASE 0 Preparations:\n"
	printf "	1. Insert MicroSD card into your computer\n"
	printf "	2. Have packages folder downloaded and in the same directory as the script\n"
	read -p "Press Enter to Continue"
	printf "\n\n"
}

#Format Drive
function p0_1 
{
	lsblk -p

	read -p "Please enter your MicroSD card device path (ex. /dev/sda) " device
	printf "\n\nWARNING: %s WILL BE FORMATTED. ALL DATA WILL BE ERASED\n\n" $device
	read -p "Press Enter to Continue or Control-C to Quit"

	printf "\nCreating new Partition Table...\n"
	parted $device mklabel msdos -s
	printf "\nCreating UEFI fat32 Patition...\n"
	parted -a opt $device mkpart primary fat32 0 400M -s >> /dev/null
	printf "\nCreating ext4 root Patition...\n"
	parted -a opt $device mkpart primary ext4 400M 100% -s >> /dev/null

	printf "\nCreating fat32 file system on boot Partition...\n"
	mkfs.vfat "${device}1"
	printf "\nCreating ext4 file system on root Partition...\n"
	mkfs.ext4 "${device}2"
}

#Mounting Drive
function p0_2
{
	printf "\nMounting boot and root partitions\n"
	mkdir boot
	mkdir root
	mount "${device}1" ./boot
	mount "${device}2" ./root
}

#Downloading Arch Linux
function p0_3
{
	if test -f ./ArchLinuxARM-rpi-armv7-latest.tar.gz; then
		rm ./ArchLinuxARM-rpi-armv7-latest.tar.gz
		printf "Deleting fragment copy of Arch Linux..."
	fi

	printf "\n\nInstalling Arch Linux\n"
	printf "	Downloading Latest ARMv7 Archlinux Tarball\n"
	wget http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-armv7-latest.tar.gz -q --show-progress
}

#Extracting and Writing Arch Linux to Root
function p0_4
{
	printf "	Extracting tarball...\n"
	bsdtar -xpf ArchLinuxARM-rpi-armv7-latest.tar.gz -C ./root
	printf "	Writing to root partition... (this can take a while)\n"
	sync
}

#Writing Pi Boot Files to Boot Partition
function p0_5
{
	printf "	Loading RPi4 boot entries to boot partition...\n"
	mv ./root/boot/* ./boot
}

#Installing Packages and Configuring miniMia
function p0_6
{
	printf "\n\nInstalling and configuring phase0 packages\n"
	printf "	Installing mia-tunnel...\n"
	cp -r ./packages/mia-tunnel ./root/usr/bin
	cp ./packages/mia-tunnel/mia.service ./root/etc/systemd/system/mia.service
	printf "	Installing minimia-updater\n"
	cp -r ./packages/minimia-updater ./root/usr/bin
	printf "	Changing hostname to minimia...\n"
	echo minimia > ./root/etc/hostname
	printf "	Enabling IPv4 and IPv6 Forwarding...\n"
	touch ./root/etc/sysctl.d/99-sysctl.conf
	echo net.ipv4.conf.all.forwarding=1 > ./root/etc/sysctl.d/99-sysctl.conf
	echo net.ipv6.conf.all.forwarding=1 >> ./root/etc/sysctl.d/99-sysctl.conf
	printf "	Placing bashrc inside root...\n"
	cp ./packages/bashrc ./root/root/.bashrc
	printf "	Placing INSTALL and REMOVE lists inside root"
	cp ./packages/INSTALL ./root/root/INSTALL
	cp ./packages/REMOVE ./root/root/REMOVE
	printf "	Removing MOTD...\n"
	rm ./root/etc/motd
}

#Configuring SSH for Root
function p0_7
{
	printf "	Enabling SSH for root...\n"
	cp ./root/etc/ssh/sshd_config ./root/etc/ssh/sshd_config_default
	echo PermitRootLogin=yes >> ./root/etc/ssh/sshd_config
}

#Clean Up
function p0_8
{
	printf "Clean up\n"
	printf "	Deleting Arch Linux Tarball...\n"
	rm ./ArchLinuxARM-rpi-armv7-latest.tar.gz
	printf "	Unmounting root and boot partitions...\n"
	umount ./boot ./root
	printf "	Removing temporary directories...\n"
	rm -rf ./root
	rm -rf ./boot
}
