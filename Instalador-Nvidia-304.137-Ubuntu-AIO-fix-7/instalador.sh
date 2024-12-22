#!/usr/bin/env bash
#===========================================
#script pra instala o driver nvidia 304.137 
#feito por Flydiscohuebr
#===========================================

#UPDATE 2024/09/16

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

#Flatpak
if command -v flatpak >/dev/null; then
  echo -e "Flatpak detectado!
Esse driver não funciona corretamente com navegadores baseados em
Chromium/Chrome e aplicações baseadas em Electron
Caso pense em utilizar alguma aplicação que se encaixe nesse cenário
passe o argumento --disable-gpu

Ex: flatpak run io.github.ungoogled_software.ungoogled_chromium --disable-gpu

Você também pode criar o arquivo chrome-flags.conf ou chromium-flags.conf
(depende do navegador) com o conteúdo --disable-gpu
em ~/.var/app/nome_do_navegador/config/
Assim não sendo necessário passar o argumento ao executar a aplicação.

Mais info aqui: https://github.com/flydiscohuebr/nvidia-304?tab=readme-ov-file#chromium-based-browsers-dont-work-properly
"
  sleep 1
fi

echo '
-----------------------------------------------------------------------
        Instalador não oficial do Driver NVidia 304-137
        Testado no Ubuntu 20.04/22.04/24.04 (kernel 6.8)
        By: Flydiscohuebr

        Problemas Durante a Instalação?
        Deixe no comentario do video :)
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
sudo apt install ./nvidia-304_304.137-0ubuntu6_amd64.deb -y || { echo "A instalação do driver falhou. Tente novamente" ; exit 1; }
sudo apt install ./nvidia-settings-legacy-304xx_304.137-0ubuntu0_amd64.deb -y || { echo "A instalação do driver falhou. Tente novamente" ; exit 1; }
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

#Flatpak
if command -v flatpak >/dev/null; then
  echo -e "[Environment]\nLD_PRELOAD=/usr/lib/x86_64-linux-gnu/GL/nvidia-304-137/lib/libGL.so.304.137:/app/lib/i386-linux-gnu/GL/nvidia-304-137/lib/libGL.so.304.137" >> ~/.local/share/flatpak/overrides/global
fi

#Chrome flatpak se detectado
#if [[ -d ~/.var/app/com.google.Chrome/config ]]; then
#  echo -e "--disable-gpu" >> ~/.var/app/com.google.Chrome/config/chrome-flags.conf
#fi

#Chromium/electron(fallback) workaround
echo -e "--disable-gpu" >> ~/.config/chromium-flags.conf
ln -s ~/.config/chromium-flags.conf ~/.config/chrome-flags.conf
ln -s ~/.config/chromium-flags.conf ~/.config/chrome-dev-flags.conf
ln -s ~/.config/chromium-flags.conf ~/.config/chrome-beta-flags.conf
ln -s ~/.config/chromium-flags.conf ~/.config/electron-flags.conf
ln -s ~/.config/chromium-flags.conf ~/.config/code-flags.conf
ln -s ~/.config/chromium-flags.conf ~/.config/codium-flags.conf

echo "Reincie o computador agora!"




