#!/usr/bin/env bash
#===========================================
#script pra instala o driver nvidia 304.137 
#feito por Flydiscohuebr
#===========================================

#update 29/07/24

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

#verificando a versão do kernel
_realextramodules="$(uname -r | cut -d"." -f1-2)"
KERVERS="linux$(echo $_realextramodules | tr -d .)"
#[[ "$_realextramodules" > 6.9 ]] && { echo "Kernel não suportado. SAINDO / Kernel not supported. leaving" ; exit 1; }
[[ "$_realextramodules" > 6.6 ]] && { echo -e "No momento os kernels acima da versão 6.6 não estão subindo o servidor X\nInstale um kernel compativel pelo Manjaro Settings Manager(ex: 6.6/6.1 e anteriores)" ; exit 1; }

if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    echo -e "KDE Plasma não funciona bem com o driver legado Nvidia 304.137\nPorem esse script possui algumas gambiarras para tornar quase utilizavel\nDeseja continuar com a instalação?"
    read -p "Aperte enter para continuar ou CTRL+C para sair"
    KDE_workaround=1
fi

#makepkg reset
cd $PWD/pacotes
cd lib32-nvidia-304xx-utils/
sudo rm -r pkg/ src/ *.zst *.tar *.run
cd ../linux-nvidia-304xx/
sudo rm -r pkg/ src/ *.zst *.tar *.run
cd ../nvidia-304xx-utils/
sudo rm -r pkg/ src/ *.zst *.tar *.run
cd ../nvidia-304xx/
sudo rm -r pkg/ src/ *.zst *.tar
cd ../../

echo '
----------------------------------------------------------
Instalador não oficial do driver nvidia 304.137 no Manjaro
by: Flydiscohuebr
qualquer duvida ou problemas durante a instalação
envia uma mensagem no meu telegram
Telegram: @Flydiscohuebr
ou no comentario do video correspondente
----------------------------------------------------------
'

echo '
IMPORTANTE IMPORTANTE IMPORTANTE IMPORTANTE
OBS: Testado com kernel 6.6 e anteriores(6.9 é suportado porem não funciona no momento)
Antes de iniciarmos, verifique se o sistema está 100% atualizado.

OBS: confirme todas as perguntas a seguir e digite sua senha de usuário quando perguntado.
Caso contrário, a instalação não pode ser bem sucedida, ok?

Dica: tenha também uma conexão com a internet estável, pois vai ser necessário.
'
read -p "Aperte enter para continuar ou ctrl+c para sair "

#instalando os kernel headers
if [[ -n $KERVERS ]]; then
    echo "kernel $KERVERS detectado instalando os headers correspondente"
    sudo pamac install "$KERVERS"-headers
fi

# isso vai ajudar a galera que não olha a descrição do video
if [ "$XDG_CURRENT_DESKTOP" = "XFCE" ]; then
    xfconf-query -c xfwm4 -p /general/vblank_mode -s xpresent
fi

#instalando os bagui necessario pra dar serto
sudo pamac install git base-devel gtk2 patchelf --no-confirm

#removendo pacotes conflitantes antes de dar merda
yes | LC_ALL=en_US.UTF-8 sudo pacman -Rc xf86-input-wacom
yes | LC_ALL=en_US.UTF-8 sudo pacman -Rc xf86-video-fbdev

#instalando o xorg 1.19 corrigido
cd $PWD/pacotes/xorg
yes | LC_ALL=en_US.UTF-8 sudo pacman -U xorg-server1.19-*
#fazendo downgrade do xf86-input-libinput para o teclado e mouse funcionar
yes | LC_ALL=en_US.UTF-8 sudo pacman -U xf86-input-libinput-*
cd ../

#instalando os bagui da nvidia agr
#nvidia-304xx-utils
cd nvidia-304xx-utils
makepkg -si --noconfirm
cd ../
#linux-nvidia-304xx
cd linux-nvidia-304xx
makepkg -si --noconfirm
cd ../
#lib32-nvidia-304xx-utils
cd lib32-nvidia-304xx-utils
makepkg -si --noconfirm
cd ../
#nvidia-304xx
cd nvidia-304xx
makepkg -si --noconfirm
cd ../

#adcionando nomodeset pro sistema iniciar sem o nouveau
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& nomodeset/' /etc/default/grub
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& nvidia_drm.modeset=1/' /etc/default/grub

#gerando mkinitcpio
sudo mkinitcpio -p $KERVERS

#atualizando o grub para fazer efeito
sudo update-grub

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
