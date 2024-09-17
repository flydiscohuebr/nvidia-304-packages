#!/usr/bin/env bash
#===========================================#
#script pra instala o driver nvidia 304.137
#feito por Flydiscohuebr
#===========================================#

#update 2024-09-17

#testes
#Verificando se e ROOT!
#==========================#
[[ "$UID" -ne "0" ]] || { echo -e "Execute esse script sem permissão root! ex: ./instalador.sh" ; exit 1 ;}
#==========================#

#por algum motivo o wget não vem instalado no debian live
if ! command -v wget >/dev/null; then
  echo -e "wget não encontrado! Instalando..."
  sudo apt install wget -y
fi

#verificando se tem interwebs
#=====================================================#
if ! wget -q --spider www.google.com; then
  echo "Não tem internet..."
  echo "Verifique se o cabo de rede esta conectado."
  exit 1
fi
#=====================================================#

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

os_release=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
debian_versi=$(cut -d. -f1 /etc/debian_version)

if [[ "$os_release" == @(*"sid"*|*"bookworm"*|*"trixie"*) ]] || [[ "$debian_versi" > "11" ]]; then
  echo "Debian 12(bookworm)/testing(trixie)/sid detectado"
  deb12_sid_detected=1
else
  echo "Debian 11/10 Detectado"
fi

notsupported_Kernel=$(uname -r | grep -Eoc 'antix|loc-os')
notsupported_KernelName=$(uname -r | grep -Eo 'antix|loc-os')
if [ $notsupported_Kernel -eq 1 ]; then
   echo -e "Você esta utilizando o kernel disponibilizado pelo $notsupported_KernelName que não e suportado por esse driver\nDeseja estar instalando o kernel disponibilizado pelo Debian?\n(compativel com o driver nvidia 304.137)\ne remover o atual?\nAperte enter para continuar ou CTRL+C para sair"
   read
   sudo apt update
   sudo apt install linux-image-amd64 linux-headers-amd64 -y
   sudo apt remove --purge linux-image-*-$notsupported_KernelName* linux-headers-*-$notsupported_KernelName* -y
	 echo "Reinicie o computador e tente novamente"
   exit 1
fi

echo '
-----------------------------------------------------------------------
        Instalador não oficial do Driver NVidia 304-137
-----------------------------------------------------------------------

Devido a esse script ter sido baseado especialmente para o Debian GNU/Linux, os repositórios contrib e non-free precisam ser ativados, principalmente se você instalou utilizando os CDs e DVDs sem os firmwares (non-free)não livres.

Como esse script pode ser usado em outras distros baseadas no Debian em geral como por ex: (MX Linux/AntiX, Q4OS, SparkyLinux, BunsenLabs, etc.) esses repositórios já podem estar ativados por padrão.

Deseja que os repositórios “contrib” e “non-free” sejam adicionados automaticamente?
OBS: No Debian 12 em diante é adicionado o repositório non-free-firmware

OBS: Caso esteja em dúvida veja o arquivo em /etc/apt/sources.list com o comando cat /etc/apt/sources.list é verifique se esse arquivo existe e está com esse repositório ativado
(Se você acabou de instalar o Debian por meio dos CDs/DVDs livres, provavelmente somente o main estará ativado)

Se estiver com dúvidas esses links vão ser uteis.
https://wiki.debian.org/pt_BR/SourcesList#Exemplo_sources.list
https://linuxdicasesuporte.blogspot.com/2020/12/habilitar-os-repositorios-contrib-non.html

Responda S/SIM para os repositórios serem colocados automaticamente
e N/NAO se esses repositórios já estiverem ativados
e aperte ctrl+c para sair
'

read -p "[S/N?] " resp1
resp1=${resp1^^}
case $resp1 in
  SIM|S)
    if [[ -n $deb12_sid_detected ]]; then
      sudo sed -r -i 's/^deb(.*)$/deb\1 contrib non-free non-free-firmware/g' /etc/apt/sources.list
      echo "contrib,non-free e non-free-firmware adicionados com sucesso"
    else
      sudo sed -r -i 's/^deb(.*)$/deb\1 contrib non-free/g' /etc/apt/sources.list
      echo "contrib e non-free adicionados com sucesso"
    fi
    ;;
  *)
    echo "continuando"
    ;;
esac

echo '
-----------------------------------------------------------------------
        Instalador não oficial do Driver NVidia 304-137
        Suportando Debian 10/11/12/testing/sid e derivados
        Testado no kernel 6.6
        By: Flydiscohuebr

        Problemas Durante a Instalação? Chame no telegram
        @Flydiscohuebr
        Ou deixe no comentario do video :)
        https://www.youtube.com/@flydiscohuebr
-----------------------------------------------------------------------
'

sleep 1

#removendo pacotes inuteis que vai atrapalhar no downgrade do xorg
#especificamente MX Linux/AntiX e seus derivados/refisefuqui?
echo "removendo pacotes conflitantes"
sudo apt remove \
virtualbox-guest-x11 \
xserver-xorg-video-cirrus \
xserver-xorg-video-mach64 \
xserver-xorg-video-mga \
xserver-xorg-video-neomagic \
xserver-xorg-video-r128 \
xserver-xorg-video-savage \
xserver-xorg-video-siliconmotion \
xserver-xorg-video-sisusb \
xserver-xorg-video-tdfx \
xserver-xorg-video-trident

sudo dpkg --add-architecture i386 #habilitando o multiarch

sudo apt update && sudo apt upgrade -y || { echo "falha ao atualizar pacotes. Tente novamente" ; exit 1; } #atualizando o sistema antes de continuar

#verificando se os kernel-headers existe
if [ $(dpkg-query -W -f='${Status}' linux-image-amd64 2>/dev/null | grep -c "ok installed") -eq 1 ] && [ $(dpkg-query -W -f='${Status}' linux-headers-amd64 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  echo "Instalando o pacote linux-headers-amd64 pois o pacote linux-image-amd64 foi encontrado"
  sudo apt install linux-headers-amd64
fi

if [[ ! -d "/usr/src/linux-headers-$(uname -r)" ]]; then
  echo "O header do kernel atual não foi encontrado! Tentando a instalação..."
  sudo apt install linux-headers-$(uname -r) || { echo "falha ao instalar os headers do kernel. Tente novamente" ; exit 1; }
fi

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

#instalando o nvidia-xconfig
#detectando a versão e instalando o pacote nvidia-xconfig compativel
if [[ -n $deb12_sid_detected ]]; then
  echo "Debian 12(bookworm)/testing/sid detectado"
  cd $PWD/utils
  sudo apt install ./nvidia-xconfig_470.103.01-1~deb11u1_amd64.deb --no-install-recommends --no-install-suggests -y
  cd ../
  sudo apt-mark hold nvidia-xconfig
else
  echo "Debian 11/10 Detectado"
  sudo apt install nvidia-xconfig --no-install-recommends --no-install-suggests -y
fi

#verificando se o nvidia-xconfig foi Instalado com sucesso
[[ $(type -P nvidia-xconfig) ]] || { echo "Falha ao instalar o nvidia-xconfig. Tente novamente" ; exit 1 ;}

#detectando a versão e instalando os pacotes correspondentes ao Debian bookworm/sid ou 11/10
if [[ -n $deb12_sid_detected ]]; then
  echo "Instalando e fazendo downgrade de alguns pacotes"
  cd $PWD/utils
  sudo apt install ./nvidia-kernel-common_20151021+13_amd64.deb -y --allow-downgrades || { echo "A instalação do pacote nvidia-kernel-common falhou. Tente novamente" ; exit 1; }
  sudo apt install ./xserver-xorg-input-libinput_1.1.0-1_amd64.deb -y --allow-downgrades || { echo "O downgrade do pacote xserver-xorg-input-libinput falhou. Tente novamente" ; exit 1; }
  sudo apt install ./xserver-xorg-input-wacom_0.34.0-1_amd64.deb -y --allow-downgrades || { echo "O downgrade do pacote xserver-xorg-input-wacom falhou. Tente novamente" ; exit 1; }
  cd ../
  sudo apt-mark hold xserver-xorg-input-libinput
  sudo apt-mark hold xserver-xorg-input-wacom
fi

#fazendo downgrade do xorg pra versao 1.19
#pacotes são compilados contendo correções de segurança CVE
#foram baixados do repositorio https://github.com/flydiscohuebr/nvidia-304
cd $PWD/xorg
sudo apt install ./*.deb -y --allow-downgrades || { echo "O downgrade do Xorg falhou. Tente novamente" ; exit 1; }
sudo apt-mark hold xserver-xorg-core
cd ../

#Instalação do driver
#Com patches aplicados para funcionar com kernels mais recentes
#https://github.com/flydiscohuebr/NVIDIA-Linux-304.137-patches
cd $PWD/driver
sudo apt install ./*.deb -y || { echo "A instalação do driver falhou. Desfazendo alterações" ; sudo apt remove \
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
xserver-xorg-video-nvidia-legacy-304xx -y ; echo "Tente a instalação novamente" ; exit 1; }

#Impedindo pacotes de serem atualizados
sudo apt-mark hold \
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
xserver-xorg-video-nvidia-legacy-304xx

sudo nvidia-xconfig #criando arquivo xorg.conf

#acima do kernel 6.1 adicionar o parametro nvidia_drm.modeset=1 por que sim
kernel_versi=$(uname -r | cut -d"." -f1-2)
if [[ "$kernel_versi" > "6.1" ]]; then
  sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& nvidia_drm.modeset=1/' /etc/default/grub
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

#Aparentemente não mais necessario
#if [[ -n $deb12_sid_detected ]]; then
#  echo "Debian 12(bookworm)/testing/sid detectado"
#  echo "Aplicando correção para aplicativos em Qt funcionar"
#  #https://forums.gentoo.org/viewtopic-p-8793005.html#8793005
#  sudo apt install patchelf -y
#  sudo patchelf --add-needed /usr/lib/x86_64-linux-gnu/libpthread.so.0 /etc/alternatives/glx--libGL.so.1-x86_64-linux-gnu
#  echo "OBS:isso não foi testado em aplicativos Qt 32 bits(I386)"
#  sudo patchelf --add-needed /usr/lib/i386-linux-gnu/libpthread.so.0 /etc/alternatives/glx--libGL.so.1-i386-linux-gnu
#fi

if [[ -e "/etc/lightdm/lightdm.conf" ]] && [[ "$os_release" == @(*"sid"*|*"trixie"*) ]] || [[ "$debian_versi" > "12" ]]; then
  echo "Debian 13(trixie)/testing/sid detectado\naplicando correção no lightdm"
  sudo sed -i 's/\[LightDM\]/[LightDM]\nlogind-check-graphical=false/' /etc/lightdm/lightdm.conf
fi

echo '
================================
Instalação concluida com sucesso
Reinicie o computador agora
================================
'
