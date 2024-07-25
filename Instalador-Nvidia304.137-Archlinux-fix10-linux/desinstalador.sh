#!/usr/bin/env bash
#Verificando se e ROOT!
#==========================
[[ "$UID" -ne "0" ]] && { echo -e "Necessita de root para executar o programa. \nexecute o comando logado como usuario root usando o comando su - \nou usando o comando sudo ex: sudo ./desinstalador.sh" ; exit 1 ;}
#==========================
#verificando se tem interwebs
#=====================================================
if ! wget -q --spider www.google.com; then
    echo "Não tem internet..."
    echo "Verifique se o cabo de rede esta conectado."
    exit 1
fi
#=====================================================

echo "desinstalando"

#comentando a linha para ignorar o pacote
sudo sed -i 's/IgnorePkg/#IgnorePkg/g' /etc/pacman.conf

#kde
if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
sudo sed -i 's/HookDir/#HookDir/g' /etc/pacman.conf
sudo rm /etc/pacman.d/hooks/novideo.hook
sudo pacman -S --noconfirm qt6-base
sudo sed -i s/KWIN_EXPLICIT_SYNC=0//g /etc/environment
sudo sed -i s/__GL_YIELD=USLEEP//g /etc/environment
sudo sed -i s/__GL_FSAA_MODE=0//g /etc/environment
sudo sed -i s/__GL_LOG_MAX_ANISO=0//g /etc/environment
sudo sed -i s/KWIN_OPENGL_INTERFACE=glx//g /etc/environment
sudo sed -i s/KWIN_NO_GL_BUFFER_AGE=1//g /etc/environment
fi

echo "removendo o driver nvidia 304"
#removendo os pacotes do driver nvidia304
pacman -R --noconfirm lib32-nvidia-304xx-utils lib32-opencl-nvidia-304xx linux-nvidia-304xx nvidia-304xx-utils opencl-nvidia-304xx lib32-opencl-nvidia-304xx

#instalando o xorg novamente
yes | LC_ALL=en_US.UTF-8 pacman -S xf86-video-nouveau xorg-server xorg-server-common xf86-input-libinput

#removendo o restante
sudo rm /etc/X11/xorg.conf.d/20-nvidia.conf
sudo rm /usr/lib/modprobe.d/blacklist_nouveau.conf
sudo rm /etc/X11/xorg.conf.nvidia-xconfig-original
sudo rm /etc/X11/xorg.conf.d/xorg.conf.nvidia-xconfig-original

#removendo nomodeset do grub
sudo sed -i s/nomodeset//g /etc/default/grub
sudo sed -i s/nvidia_drm.modeset=1//g /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

#mkinitcpio
pacman -Q dracut &> /dev/null
if [ $? -eq 0 ]; then
    echo "Dracut detectado"
    sudo dracut --force /boot/initramfs-linux.img
    sudo dracut -N --force /boot/initramfs-linux-fallback.img
else
    sudo mkinitcpio -p linux
fi

echo "so reinciar agora"
