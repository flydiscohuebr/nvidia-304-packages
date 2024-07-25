#!/usr/bin/env bash
echo "
Desinstalando e removendo o driver Nvidia-304.137
"
sudo apt-mark unhold xserver-xorg-core xserver-xorg-input-libinput nvidia-304
sudo apt remove --purge "*nvidia*" && sudo apt autoremove --purge
sudo rm /etc/X11/xorg.conf
sudo rm /etc/X11/xorg.conf.backup
sudo rm /etc/X11/xorg.conf.nvidia-xconfig-original 
sudo apt update && sudo apt upgrade && sudo apt install xserver-xorg-core xserver-xorg-video-all -y
#acima do kernel 6.1 adicionar o parametro nvidia_drm.modeset=1 por que sim
kernel_versi=$(uname -r | cut -d"." -f1-2)
if [[ "$kernel_versi" > "6.1" ]]; then
	sudo sed -i 's/nvidia_drm.modeset=1//g' /etc/default/grub
fi
echo "Pronto agora e so reiniciar o computador"
