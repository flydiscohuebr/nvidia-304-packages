#!/usr/bin/env bash
#===========================================#
#script pra remover o driver nvidia 304.137 
#feito por Flydiscohuebr
#===========================================#

#testes
#Verificando se e ROOT!
#==========================#
[[ "$UID" -ne "0" ]] && { echo -e "Necessita de root para executar o programa. \nexecute o comando logado como usuario root usando o comando su - \nou usando o comando sudo ex: sudo ./instalador.sh" ; exit 1 ;}
#==========================#

#verificando se tem interwebs
#=====================================================#
if ! wget -q --spider www.google.com; then
    echo "Não tem internet..."
    echo "Verifique se o cabo de rede esta conectado."
    exit 1
fi
#=====================================================#

echo '
-----------------------------------------------------------------------
               Desinstalando o Driver NVidia 304-137
-----------------------------------------------------------------------
'

sudo apt-mark unhold \
libgl1-nvidia-legacy-304xx-glx \
libnvidia-legacy-304xx-cfg1 \
libnvidia-legacy-304xx-cfg1:i386 \
libnvidia-legacy-304xx-glcore \
libnvidia-legacy-304xx-ml1 \
nvidia-legacy-304xx-alternative \
nvidia-legacy-304xx-driver \
nvidia-legacy-304xx-driver-bin \
nvidia-legacy-304xx-driver-libs \
nvidia-legacy-304xx-driver-libs:i386 \
nvidia-legacy-304xx-kernel-dkms \
nvidia-legacy-304xx-kernel-support \
nvidia-legacy-304xx-vdpau-driver \
nvidia-settings-legacy-304xx \
xserver-xorg-video-nvidia-legacy-304xx \
xserver-xorg-core \
xserver-xorg-input-libinput \
nvidia-xconfig \
xserver-xorg-input-wacom

sudo apt remove --purge "*nvidia*" && sudo apt autoremove --purge
sudo apt update && sudo apt upgrade -y
sudo apt remove libnvidia-legacy-304xx-glcore

sudo rm /etc/X11/xorg.conf
sudo rm /etc/X11/xorg.conf.backup
sudo rm /etc/X11/xorg.conf.nvidia-xconfig-original

#acima do kernel 6.1 adicionar o parametro nvidia_drm.modeset=1 por que sim
kernel_versi=$(uname -r | cut -d"." -f1-2)
if [[ "$kernel_versi" > "6.1" ]]; then
	sudo sed -i 's/nvidia_drm.modeset=1//g' /etc/default/grub
  sudo update-grub
fi

echo "Driver Removido com sucesso"
