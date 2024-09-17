#!/usr/bin/env bash
#===========================================#
#script pra instala o driver nvidia 304.137
#feito por Flydiscohuebr
#===========================================#

#update ter 17 set 2024 00:55

#testes
#Verificando se e ROOT!
#==========================#
[[ "$UID" -ne "0" ]] || { echo -e "Execute esse script sem permissão root! ex: ./instalador.sh" ; exit 1 ;}
#==========================#

#por algum motivo o wget não vem instalado no debian live
if ! command -v wget >/dev/null; then
  echo -e "Esse script requer o wget instalado! Saindo...\nvocê pode instalar rodando o comando sudo apt install wget -y"
  exit 1
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

echo '
!!!!!!!!!!!!!!! Parado ae !!!!!!!!!!!!!!!!!
E importante que antes da instalação você tenha um kernel com o lkdtm habilitado
caso contrario a instalação ira falhar
olhe esse video antes da instalação: https://youtu.be/dVQ6AsQmJFw

Qualquer duvida sobre isso envie uma mensagem no comentario do video
https://www.youtube.com/@flydiscohuebr
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Aperte enter para continuar ou ctrl+c para sair
'
read

checkforlkdtm=$(find /lib/modules/$(uname -r) -type f -name '*.ko*' | grep -c lkdtm.ko)
if [ $checkforlkdtm -eq 1 ]; then
	echo "Modulo LKDTM detectado! Continuando..."
else
	echo -e "Você precisa estar utilizando um kernel com o modulo lkdtm como explicado acima\nInstale um kernel compativel ou compile o kernel com a opção CONFIG_LKDTM habilitado como modulo e tente novamente.\nSaindo..."
	exit 1
fi

#antiXkernel=$(uname -r | grep -c "antix")
#if [ $antiXkernel -eq 1 ]; then
#	sudo apt remove --purge linux-image-*-antix* linux-headers-*-antix* -y
#fi

echo '
-----------------------------------------------------------------------
        Instalador não oficial do Driver NVidia 304-137
                            32-Bits
-----------------------------------------------------------------------

Devido a esse script ter sido baseado especialmente para o Debian GNU/Linux
os repositorios contrib e non-free precisam ser ativados principalmente se
você instalou utilizando os cds e dvds sem os firmwares (non-free)nao livres.

Como esse script pode ser usado em outras distros baseadas no Debian em geral como
por ex: (MX Linux/AntiX, Q4OS, SparkyLinux, BunsenLabs e etc.) esses repositorios 
ja podem estar ativados por padrão.

Deseja que os repositorios "contrib" e "non-free"
sejam adicionados automaticamente?
OBS:No Debian 12 em diante é adicionado o repositorio non-free-firmware

OBS: Caso esteja em duvida veja o arquivo em /etc/apt/sources.list
com o comando cat /etc/apt/sources.list
é verifique se esse arquivo existe e esta com esses repositorios ativado
(Se você acabou de instalar o Debian por meio dos cds/dvds livres provavelmente somente o main vai estar ativado)

Se estiver com duvidas esses links vão ser uteis
https://wiki.debian.org/pt_BR/SourcesList#Exemplo_sources.list
https://linuxdicasesuporte.blogspot.com/2020/12/habilitar-os-repositorios-contrib-non.html

Responda S/SIM para que os repositorios sejam colocados automaticamente
e N/NAO se esses repositorios ja estiverem ativados
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
        Instalador não oficial do Driver NVidia 304-137 32-Bits
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

#sudo dpkg --add-architecture i386 #habilitando o multiarch

sudo apt update && sudo apt upgrade -y || { echo "falha ao atualizar pacotes. Tente novamente" ; exit 1; } #atualizando o sistema antes de continuar

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
	sudo apt install ./nvidia-xconfig_470.103.01-1~deb11u1_i386.deb --no-install-recommends --no-install-suggests -y
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
  echo "Debian 12(bookworm)/testing/sid detectado"
  cd $PWD/utils
  sudo apt install ./nvidia-kernel-common_20151021+13_i386.deb -y --allow-downgrades || { echo "A instalação do pacote nvidia-kernel-common falhou. Tente novamente" ; exit 1; }
  sudo apt install ./xserver-xorg-input-libinput_1.1.0-1_i386.deb -y --allow-downgrades || { echo "O downgrade do pacote xserver-xorg-input-libinput falhou. Tente novamente" ; exit 1; }
  sudo apt install ./xserver-xorg-input-wacom_0.34.0-1_i386.deb -y --allow-downgrades || { echo "O downgrade do pacote xserver-xorg-input-wacom falhou. Tente novamente" ; exit 1; }
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

#instalação do driver
#com patches aplicados para funcionar com kernels mais recentes
#https://github.com/flydiscohuebr/NVIDIA-Linux-304.137-patches
cd $PWD/driver
sudo apt install ./*.deb -y || { echo "A instalação do driver falhou. Desfazendo alterações" ; sudo apt remove \
libgl1-nvidia-legacy-304xx-glx \
libgl1-nvidia-legacy-304xx-glx:i386 \
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

#impedindo pacotes de serem atualizados
sudo apt-mark hold \
libgl1-nvidia-legacy-304xx-glx \
libgl1-nvidia-legacy-304xx-glx:i386 \
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
  echo -e "[Environment]\nLD_PRELOAD=/app/lib/i386-linux-gnu/GL/nvidia-304-137/lib/libGL.so.304.137" >> ~/.local/share/flatpak/overrides/global
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
#	echo "Debian 12(bookworm)/testing/sid detectado"
#	echo "Não testado na versão 32 bits! Problemas? me avise"
#	echo "Aplicando correção para aplicativos em Qt funcionar"
#	#https://forums.gentoo.org/viewtopic-p-8793005.html#8793005
#	sudo apt install patchelf -y
#	sudo patchelf --add-needed /usr/lib/i386-linux-gnu/libpthread.so.0 /etc/alternatives/glx--libGL.so.1-i386-linux-gnu
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
