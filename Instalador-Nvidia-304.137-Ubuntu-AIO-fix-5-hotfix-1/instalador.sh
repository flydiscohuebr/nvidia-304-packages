#!/usr/bin/env bash
#===========================================
#script pra instala o driver nvidia 304.137 
#feito por Flydiscohuebr
#===========================================

#UPDATE 2024/09/05

#testes
#Verificando se e ROOT!
#==========================
[[ "$UID" -ne "0" ]] || { echo -e "Execute esse script sem permissão root! ex: ./instalador.sh" ; exit 1 ;}
#==========================

#verificando se tem interwebs
#=====================================================
if ! wget -q --spider www.google.com; then
    echo "Não tem internet..."
    echo "Verifique se o cabo de rede esta conectado."
    exit 1
fi
#=====================================================

echo '
-----------------------------------------------------------------------
        Instalador não oficial do Driver NVidia 304-137
        Testado no Ubuntu 20.04/22.04/23.04/23.10 (kernel 6.6)
        By: Flydiscohuebr

        Problemas Durante a Instalação? Chame no telegram
        @Flydiscohuebr
        Ou deixe no comentario do video :)
        https://www.youtube.com/@flydiscohuebr
-----------------------------------------------------------------------
'

#habilitar o multiarch
sudo dpkg --add-architecture i386

#atualizar a lista de pacotes
sudo apt update

#instalando alguns pacotes uteis para depois
sudo apt install build-essential dkms patchelf flex bison libgl1-mesa-dri:i386 libgl1:i386 libc6:i386 linux-headers-$(uname -r) -y

#fazendo downgrade do xorg pra versao 1.19
#pacotes são compilados contendo correções de segurança CVE
#foram baixados do repositorio https://github.com/flydiscohuebr/nvidia-304
cd $PWD/xorg
sudo apt install ./xserver-xorg-input-libinput_1.1.0-1_amd64.deb --allow-downgrades -y || { echo "O downgrade do Xorg falhou. Tente novamente" ; exit 1; }
sudo apt install ./xserver-xorg-core_1.19.6-1ubuntu7_amd64.deb --allow-downgrades -y || { echo "O downgrade do Xorg falhou. Tente novamente" ; exit 1; }
sudo apt-mark hold xserver-xorg-core xserver-xorg-input-libinput
cd ../

# isso vai ajudar a galera que não olha a descrição do video
if [ "$XDG_CURRENT_DESKTOP" = "XFCE" ]; then
  xfconf-query -c xfwm4 -p /general/vblank_mode -s xpresent || { xfconf-query -c xfwm4 -p /general/vblank_mode -t string -s "xpresent" --create;}
  #sed -i '/vblank_mode/s/auto/xpresent/g' /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
fi

# se a distro utiliza outro ambiente grafico e o xfwm4 como gerenciador de janelas isso vai ser util
if [ $(dpkg-query -W -f='${Status}' xfwm4 2>/dev/null | grep -c "ok installed") -eq 1 ] && [ $(dpkg-query -W -f='${Status}' xfconf 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
  xfconf-query -c xfwm4 -p /general/vblank_mode -s xpresent || { xfconf-query -c xfwm4 -p /general/vblank_mode -t string -s "xpresent" --create;}
  #sed -i '/vblank_mode/s/auto/xpresent/g' /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
fi

#Instalação do driver
#Com patches aplicados para funcionar com kernels mais recentes
#https://github.com/flydiscohuebr/NVIDIA-Linux-304.137-patches
cd $PWD/driver
sudo apt install ./nvidia-304_304.137-0ubuntu5_amd64.deb -y || { echo "A instalação do driver falhou. Tente novamente" ; exit 1; }
sudo apt-mark hold nvidia-304
cd ../

#criando arquivo xorg.conf
sudo nvidia-xconfig --no-logo

sudo sed -i /'Section "Files"'/,/'EndSection'/s%'EndSection'%"\tModulePath \"/usr/lib/nvidia-304/xorg\" \nEndSection"%g "/etc/X11/xorg.conf"
sudo sed -i /'Section "Files"'/,/'EndSection'/s%'EndSection'%"\tModulePath \"/usr/lib/xorg/modules\" \nEndSection"%g "/etc/X11/xorg.conf"
sudo sed -i 's/HorizSync/#HorizSync/' /etc/X11/xorg.conf
sudo sed -i 's/VertRefresh/#VertRefresh/' /etc/X11/xorg.conf

#reinstalando o vdpau para corrigir problemas ao reproduzir videos e etc
echo "reinstalando libvdpau1"
sudo apt install --reinstall libvdpau1

#acima do kernel 6.1 adicionar o parametro nvidia_drm.modeset=1 por que sim
kernel_versi=$(uname -r | cut -d"." -f1-2)
if [[ "$kernel_versi" > "6.1" ]]; then
  sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& nvidia_drm.modeset=1/' /etc/default/grub
  #Extra - nvidia_drm.modeset=1 não esta desabilitando o simpledrm/framebuffer na maioria dos casos
  sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& initcall_blacklist=simpledrm_platform_driver_init/' /etc/default/grub
  sudo update-grub
fi

#fix segmentation fault (versões recentes do ubuntu)
#talvez não mais necessario
sudo patchelf --add-needed /usr/lib/x86_64-linux-gnu/libpthread.so.0 /usr/lib/x86_64-linux-gnu/libGL.so.304.137

#echo "
#TODO:
#"
#read -p "[S/N?] " resp1
#resp1=${resp1^^}
#case $resp1 in
#  SIM|S)
#    if [[ -f "/lib/x86_64-linux-gnu/libEGL.so.1" ]]; then
#      sudo rm -rf /lib/x86_64-linux-gnu/libEGL*
#    fi
#    ;;
#  *)
#    echo "continuando"
#    ;;
#esac

echo "Reincie o computador agora!"




