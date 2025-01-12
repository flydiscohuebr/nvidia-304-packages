#!/usr/bin/env bash
#===========================================
#script pra instala o driver nvidia 304.137 
#feito por Flydiscohuebr
#===========================================

#UPDATE 2025/01/12

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

#Cinnamon
if [ "$XDG_CURRENT_DESKTOP" = "Cinnamon" ] || [ "$XDG_CURRENT_DESKTOP" = "X-Cinnamon" ]; then
  echo "Cinnamon detectado!"
  echo "A ultima versão funcional do cinnamon foi a 5.2.1 presente no Mint 20"
  echo "Se você não esta utilizando o mint 20 ou a versão especificada espere por problemas :)"
  echo "Aperte enter para continuar mesmo assim ou CTRL+C para sair"
  echo "PROTIP: considere atualizar seu hardware XD"
  read
fi

#Gnome?
if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
  echo "Gnome detectado :( Leia a descrição do video! Saindo..."
  echo "Caso não saiba o Gnome não funciona com esse driver legado por motivos obvios"
  echo "PROTIP: considere atualizar seu hardware XD"
  exit 1
fi

#KDE
if [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
  echo "O ambiente grafico KDE pode não funcionar corretamente"
  echo "Talvez seja necessario o parametro OpenGLIsUnsafe=true nas configurações do kwin"
  echo "https://youtu.be/OQP9Q9X3PVo"
  echo "PROTIP: considere atualizar seu hardware XD"
  sleep 1
fi

fudeu () {
  mkdir -p $PWD/logs
  cp /var/lib/dkms/nvidia-304/304.137/build/make.log $PWD/logs 2>/dev/null
  sudo cp /var/log/apt/term.log $PWD/logs
  sudo chmod 777 $PWD/logs/term.log
  sudo sudo journalctl -b -r | head -n 50 > $PWD/logs/journalctl.log
  sudo dmesg | tail -50 > $PWD/logs/dmesg.log
  echo -e "\n!!!!!!!!!!Atenção!!!!!!!!!!!\nAparentemente deu tudo errado e a instalação falhou, por favor envie os logs presentes na pasta logs no meu Telegram ou por algum serviço de paste como pastebin, debian pastezone, openSUSE Paste, github gist, etc. E envie os links pelo comentário do YouTube ou no Telegram."
}

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
EXTRA: Aplicativos que utilizam Flutter também não funcionam até o momento
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
sudo apt install build-essential dkms patchelf flex bison libgl1-mesa-dri:i386 libgl1:i386 libc6:i386 linux-headers-generic linux-headers-$(uname -r) -y

#fazendo downgrade do xorg pra versao 1.19
#pacotes são compilados contendo correções de segurança CVE
#foram baixados do repositorio https://github.com/flydiscohuebr/nvidia-304
cd $PWD/xorg
sudo apt install ./xserver-xorg-input*.deb --allow-downgrades -y || { echo "O downgrade do Xorg falhou. Tente novamente" ; exit 1; }
sudo apt install ./xserver-xorg-core_1.19.6-1ubuntu*_amd64.deb --allow-downgrades -y || { echo "O downgrade do Xorg falhou. Tente novamente" ; exit 1; }
sudo apt-mark hold xserver-xorg-core xserver-xorg-input-libinput
cd ../

# isso vai ajudar a galera que não olha a descrição do video
if [ "$XDG_CURRENT_DESKTOP" = "XFCE" ]; then
  xfconf-query -c xfwm4 -p /general/vblank_mode -s xpresent || { xfconf-query -c xfwm4 -p /general/vblank_mode -t string -s "xpresent" --create;}
fi

# se a distro utiliza outro ambiente grafico e o xfwm4 como gerenciador de janelas isso vai ser util
if [ $(dpkg-query -W -f='${Status}' xfwm4 2>/dev/null | grep -c "ok installed") -eq 1 ] && [ $(dpkg-query -W -f='${Status}' xfconf 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
  xfconf-query -c xfwm4 -p /general/vblank_mode -s xpresent || { xfconf-query -c xfwm4 -p /general/vblank_mode -t string -s "xpresent" --create;}
fi

#all end
if [ $(dpkg-query -W -f='${Status}' xfwm4 2>/dev/null | grep -c "ok installed") -eq 1 ] && [ $(dpkg-query -W -f='${Status}' xfconf 2>/dev/null | grep -c "ok installed") -eq 1 ] && [ $(command -v xfconf-query >/dev/null) -eq 1 ]; then
  sed -i '/vblank_mode/s/auto/xpresent/g' /home/$USER/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
fi

#Instalação do driver
#Com patches aplicados para funcionar com kernels mais recentes
#https://github.com/flydiscohuebr/NVIDIA-Linux-304.137-patches
cd $PWD/driver
sudo apt install ./nvidia-304_304.137-0ubuntu*_amd64.deb -y || { echo "A instalação do driver falhou. Tente novamente" ; fudeu ; exit 1; }
sudo apt install ./nvidia-settings-legacy-304xx_304.137-*_amd64.deb -y || { echo "A instalação do driver falhou. Tente novamente" ; exit 1; }
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

#acima do kernel 5.17 adicionar o parametro nvidia_drm.modeset=1 por que sim
kernel_versi=$(uname -r | cut -d"." -f1-2)
if [[ "$kernel_versi" > "5.17" ]]; then
  sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& nvidia_drm.modeset=1/' /etc/default/grub
  #Extra - nvidia_drm.modeset=1 não esta desabilitando o simpledrm/framebuffer na maioria dos casos
  sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& initcall_blacklist=simpledrm_platform_driver_init/' /etc/default/grub
  #Algumas distros utilizam aspas simples
  sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT='[^']*/& nvidia_drm.modeset=1/" /etc/default/grub
  #Extra - nvidia_drm.modeset=1 não esta desabilitando o simpledrm/framebuffer na maioria dos casos
  sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT='[^']*/& initcall_blacklist=simpledrm_platform_driver_init/" /etc/default/grub
  sudo update-grub
fi

#Flatpak
if command -v flatpak >/dev/null; then
  mkdir -p ~/.local/share/flatpak/overrides
  echo -e "[Environment]\nLD_PRELOAD=/usr/lib/x86_64-linux-gnu/GL/nvidia-304-137/lib/libGL.so.304.137:/app/lib/i386-linux-gnu/GL/nvidia-304-137/lib/libGL.so.304.137" >> ~/.local/share/flatpak/overrides/global
fi

#Chrome flatpak se detectado
#if [[ -d ~/.var/app/com.google.Chrome/config ]]; then
#  echo -e "--disable-gpu" >> ~/.var/app/com.google.Chrome/config/chrome-flags.conf
#fi

#Chromium/electron(fallback) workaround
#aparentemente somente valido para o archlinux
#echo -e "--disable-gpu" >> ~/.config/chromium-flags.conf
#ln -s ~/.config/chromium-flags.conf ~/.config/chrome-flags.conf
#ln -s ~/.config/chromium-flags.conf ~/.config/chrome-dev-flags.conf
#ln -s ~/.config/chromium-flags.conf ~/.config/chrome-beta-flags.conf
#ln -s ~/.config/chromium-flags.conf ~/.config/electron-flags.conf
#ln -s ~/.config/chromium-flags.conf ~/.config/code-flags.conf
#ln -s ~/.config/chromium-flags.conf ~/.config/codium-flags.conf

echo "Reincie o computador agora!"




