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
echo '
============================================================
AVISO ANTES DE REMOVER O DRIVER
responda sim/yes S/Y a todas as perguntas do pacman a seguir caso contrario o driver pode falhar

e tambem
nao esqueca de remover o xf86-input-libinput do IgnorePkg caso tenha adcionado
comente a linha IgnorePkg no arquivo /etc/pacman.conf
ficando mais ou menos assim

#IgnorePkg   =

============================================================
'
#echo '
#voce tambem pode usar esse comando
#sudo sed -i 's/IgnorePkg = xf86-input-libinput/#IgnorePkg   =/g' /etc/pacman.conf
#OBS: se voce ja tiver outros pacotes adicionados a IgnorePkg recomendo fazer isso manualmente ao invez de usar o comando
#'
read -p "aperte enter para continuar ou ctrl+c para sair "

echo "removendo o driver nvidia 304"
#removendo os pacotes do driver nvidia304
pacman -R lib32-nvidia-304xx-utils lib32-opencl-nvidia-304xx linux-lts-nvidia-304xx nvidia-304xx-utils opencl-nvidia-304xx
#instalando o xorg novamente
pacman -S xf86-video-nouveau xorg-server xorg-server-common xf86-input-libinput
pacman -R xorg-server1.19-xephyr-git
#removendo o restante
sudo rm /etc/X11/xorg.conf.d/20-nvidia.conf
sudo rm /usr/lib/modprobe.d/blacklist_nouveau.conf
sudo rm /etc/X11/xorg.conf.nvidia-xconfig-original
#removendo nomodeset do grub
sudo sed s/nomodeset//g /etc/default/grub > /tmp/sexo
sudo mv /tmp/sexo /etc/default/grub
sudo sed s/nvidia_drm.modeset=1//g /etc/default/grub > /tmp/sexo
sudo mv /tmp/sexo /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo rm /tmp/sexo
#fim
#mkinitcpio
pacman -Q dracut &> /dev/null
if [ $? -eq 0 ]; then
    echo "Dracut detectado"
    sudo dracut --force /boot/initramfs-linux-lts.img
    sudo dracut -N --force /boot/initramfs-linux-lts-fallback.img
else
    sudo mkinitcpio -p linux-lts
fi
echo "so reinciar agora"
