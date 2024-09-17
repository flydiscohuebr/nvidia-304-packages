#!/usr/bin/env bash
#Verificando se e ROOT!
#==========================
[[ "$UID" -ne "0" ]] && { echo -e "Necessita de root para executar o programa. \nexecute o comando logado como usuario root usando o comando su - \nou usando o comando sudo ex: sudo ./desinstalador.sh" ; exit 1 ;}
#==========================
#wget
if ! command -v wget >/dev/null; then
    echo "wget não encontrado! Instalando..."
    sudo pacman -S wget --noconfirm
fi
#verificando se tem interwebs
#=====================================================
if ! wget -q --spider www.google.com; then
    echo "Não tem internet..."
    echo "Verifique se o cabo de rede esta conectado."
    exit 1
fi
#=====================================================
#var
KERVERS=""

#verificando o kernel
_realextramodules="$(uname -r | cut -d"." -f1-2)"
KERVERS="linux$(echo $_realextramodules | tr -d .)"
#

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

echo "desinstalando"
#removendo os pacotes do driver
pamac remove nvidia-304xx-utils lib32-nvidia-304xx-utils "$KERVERS"-nvidia-304xx nvidia-304xx opencl-nvidia-304xx lib32-opencl-nvidia-304xx --no-confirm

#reinstalando o xorg e o driver nouveau 
pamac install xf86-video-nouveau xf86-video-fbdev xf86-video-vesa xorg-server xorg-server-common xf86-input-libinput --no-confirm

#removendo nomodeset do grub
sudo sed -i s/nomodeset//g /etc/default/grub
sudo sed -i s/nvidia_drm.modeset=1//g /etc/default/grub
sudo sed -i s/initcall_blacklist=simpledrm_platform_driver_init//g /etc/default/grub

#flatpak
#sudo rm ~/.var/app/com.google.Chrome/config/chrome-flags.conf
sudo rm ~/.local/share/flatpak/overrides/global

#chromium misc
sudo rm ~/.config/chromium-flags.conf
sudo rm ~/.config/chrome-flags.conf
sudo rm ~/.config/chrome-dev-flags.conf
sudo rm ~/.config/chrome-beta-flags.conf
sudo rm ~/.config/electron-flags.conf
sudo rm ~/.config/code-flags.conf
sudo rm ~/.config/codium-flags.conf

#fim
sudo mkinitcpio -P
sudo update-grub
echo "pronto reiniciar agr ok"
