#!/usr/bin/env bash
#===========================================
#script pra instala o driver nvidia 304.137 
#feito por Flydiscohuebr
#===========================================

#update 2024-06-30

#testes
#Verificando se e ROOT!
#==========================
[[ "$UID" -ne "0" ]] || { echo -e "Execute sem permissao root" ; exit 1 ;}
#==========================

#verificando se tem interwebs
#=====================================================
if ! wget -q --spider www.google.com; then
    echo "Não tem internet..."
    echo "Verifique se o cabo de rede esta conectado."
    exit 1
fi
#=====================================================

if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    echo -e "KDE Plasma não funciona bem com o driver legado Nvidia 304.137\nPorem esse script possui algumas gambiarras para tornar quase utilizavel\nDeseja continuar com a instalação?"
    read -p "Aperte enter para continuar ou CTRL+C para sair"
    KDE_workaround=1
fi

#makepkg reset
#
cd $PWD/pacotes
cd lib32-nvidia-304xx-utils/
sudo rm -r pkg/ src/ *.zst *.run *.tar
cd ../nvidia-304xx/
sudo rm -r pkg/ src/ *.zst *.run *.tar
cd ../nvidia-304xx-utils/
sudo rm -r pkg/ src/ *.zst *.run *.tar
cd ../../
#

#identificando se o linux-headers esta instalado
#
pacman -Q linux-headers &> /dev/null
if [ ! $? -eq 0 ]; then
    echo "O pacote linux-headers nao foi detectado"
    echo "Instalando agora"
    sudo pacman -S --needed --noconfirm linux-headers
fi

echo '
-----------------------------------------------------------------------
Instalador nao oficial do driver nvidia 304.137
by: Flydiscohuebr
qualquer erro ou problema durante a instalação envie uma mensagem no meu telegram
Telegram: @Flydiscohuebr
ou no comentario do video correspondente
-----------------------------------------------------------------------

IMPORTANTE IMPORTANTE IMPORTANTE IMPORTANTE

OBS: Testado com kernel 6.9 e anteriores
Antes de iniciarmos, verifique se o sistema está 100% atualizado.

OBS: confirme todas as perguntas a seguir e digite sua senha de usuário quando perguntado.
Caso contrário, a instalação não pode ser bem sucedida, ok?

Dica: tenha também uma conexão com a internet estável, pois vai ser necessário.

IMPORTANTE IMPORTANTE IMPORTANTE IMPORTANTE
'

read -p "aperte enter para continuar ou ctrl+c para sair "

# isso vai ajudar a galera que não olha a descrição do video
if [ "$XDG_CURRENT_DESKTOP" = "XFCE" ]; then
    xfconf-query -c xfwm4 -p /general/vblank_mode -s xpresent
fi

#pacotes necessarios
sudo pacman -S --needed --noconfirm git gtk2 base-devel patchelf

#pacotes conflitantes
yes | LC_ALL=en_US.UTF-8 sudo pacman -Rc xf86-input-wacom
yes | LC_ALL=en_US.UTF-8 sudo pacman -Rc xf86-video-fbdev

#instalando xorg
cd $PWD/pacotes/xorg
yes | LC_ALL=en_US.UTF-8 sudo pacman -Ud xorg-server1.19-*
#downgrade libinput para funcionar teclado e mouse
yes | LC_ALL=en_US.UTF-8 sudo pacman -U xf86-input-libinput-*
cd ../

#instalando os bagui da nvidia agr
#nvidia-304xx-utils
cd nvidia-304xx-utils
makepkg -si --noconfirm
cd ../
#nvidia-304xx
cd nvidia-304xx
makepkg -si --noconfirm
cd ../
#lib32-nvidia-304xx-utils
cd lib32-nvidia-304xx-utils
makepkg -si --noconfirm
cd ../

#criando o xorg.conf e movendo pra /etc/X11/xorg.conf.d
sudo nvidia-xconfig -o "/etc/X11/xorg.conf.d/20-nvidia.conf" --composite --no-logo
sudo sed -i /'Section "Files"'/,/'EndSection'/s%'EndSection'%"\tModulePath \"/usr/lib64/nvidia/xorg\" \nEndSection"%g /etc/X11/xorg.conf.d/20-nvidia.conf
sudo sed -i /'Section "Files"'/,/'EndSection'/s%'EndSection'%"\tModulePath \"/usr/lib64/xorg/modules\" \nEndSection"%g /etc/X11/xorg.conf.d/20-nvidia.conf
sudo sed -i 's/HorizSync/#HorizSync/' /etc/X11/xorg.conf.d/20-nvidia.conf
sudo sed -i 's/VertRefresh/#VertRefresh/' /etc/X11/xorg.conf.d/20-nvidia.conf

#colocando nouveau e seus amigos na blacklist
sudo cp blacklist_nouveau.conf /usr/lib/modprobe.d/

#adcionando nomodeset
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& nomodeset/' /etc/default/grub
sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT='[^']*/& nomodeset/" /etc/default/grub
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& nvidia_drm.modeset=1/' /etc/default/grub
sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT='[^']*/& nvidia_drm.modeset=1/" /etc/default/grub
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

#fix segfault
sudo patchelf --add-needed /usr/lib64/libpthread.so.0 /usr/lib/nvidia/libGL.so.304.137

#ignorando o pacote libinput
sudo sed -i 's/#IgnorePkg   =/IgnorePkg = xf86-input-libinput/g' /etc/pacman.conf

if grep -q "#IgnorePkg = xf86-input-libinput" /etc/pacman.conf ; then
    sudo sed -i 's/#IgnorePkg/IgnorePkg/g' /etc/pacman.conf
fi

#kde
if [ "$KDE_workaround" = "1" ]; then
    echo -e "\n[QtQuickRendererSettings]\nRenderLoop=basic\nSceneGraphBackend=opengl" >> ~/.config/kdeglobals
    sudo sed -i 's/#HookDir/HookDir/g' /etc/pacman.conf
    sudo mkdir /etc/pacman.d/hooks/
sudo bash -c "echo '[Trigger]
Operation=Install
Operation=Upgrade
Type=Package
Target=qt6-base

[Action]
Description=Patching Nvidia libGL in libQt6Gui.so.6
Depends=patchelf
When=PostTransaction
Exec=/usr/bin/patchelf --add-needed /usr/lib/nvidia/libGL.so.1 /usr/lib/libQt6Gui.so.6' > /etc/pacman.d/hooks/novideo.hook"
sudo bash -c "echo 'KWIN_EXPLICIT_SYNC=0
__GL_YIELD=USLEEP
__GL_FSAA_MODE=0
__GL_LOG_MAX_ANISO=0
KWIN_OPENGL_INTERFACE=glx
KWIN_NO_GL_BUFFER_AGE=1' >> /etc/environment"
echo '
Aparentemente foi tudo instalado com sucesso
reinicie o computador agora
qualquer coisa
Telegram: @Flydiscohuebr
ou escreva um comentario no video que vc baixou isso :)
'
    sudo patchelf --add-needed /usr/lib/nvidia/libGL.so.1 /usr/lib/libQt6Gui.so.6
fi

echo '
Aparentemente foi tudo instalado com sucesso
reinicie o computador agora
qualquer coisa
Telegram: @Flydiscohuebr
ou escreva um comentario no video que vc baixou isso :)
'
