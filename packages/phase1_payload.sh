#!/bin/bash

printf "Pacman Setup + Install and Remove Packages:\n"
printf "	Creating and Updating Keyrings...\n"
pacman-key --init
pacman-key --populate archlinuxarm
printf "	Updating full system and mirrors...\n"
pacman -Syyu --noconfirm
printf "	Installing all packages in install list...\n"
while read package; do
	pacman -S $package --noconfirm
done < ./INSTALL
printf "	Removing all packages in remove list...\n"
while read package; do
	pacman -Rs $package --noconfirm
done < ./REMOVE

printf "\n\nConfigure Services\n"
printf "	Enabling tailscale service...\n"
systemctl enable tailscaled
systemctl start tailscaled
printf "	Enabling mia-tunnel service...\n"
systemctl enable mia.service
printf "	Installing RPi Module from AUR...\n"
cd /tmp
git clone https://aur.archlinux.org/python-rpi-gpio.git
chmod 777 ./python-rpi-gpio
cd ./python-rpi-gpio
runuser -unobody makepkg
pacman -U python-rpi-gpio-0.7.1-1-any.pkg.tar.xz --noconfirm
cd ~
printf "	Configuring the group wheel to be able to use sudo...\n"
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
printf "	Login to Tailscale\n"
tailscale up

printf "\n\nCreating and Configuring default user (mia)\n"
printf "	Creating mia user...\n"
useradd -m mia
printf "	Changing mia password to default password (mamamia)\n"
echo "mia:mamamia" | chpasswd
printf "	Add mia user to the group wheel\n"
usermod -aG wheel mia
printf "	Copying bashrc to mia home directory\n"
cp -f ./.bashrc /home/mia/.bashrc
printf "	Removing alarm...\n"
userdel -r alarm

printf "\n\nClean up and Final Configuration\n"
printf "	Removing root SSH access...\n"
rm /etc/ssh/sshd_config
mv /etc/ssh/sshd_config_default /etc/ssh/sshd_config
printf "	Changing root password to default password\n"
echo "root:mamamia" | chpasswd
printf "	Removing INSTALL and REMOVE lists from root\n"
rm ./INSTALL
rm ./REMOVE

printf "Installation Complete! Rebooting!\n\n"
reboot now

