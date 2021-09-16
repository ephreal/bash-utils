#!/bin/bash


# Ordered list of packages that must be installed.
# Linphone is last.
pkgs=(
        "libdecaf"
        "bctoolbox-git"
        "liblinphone-git"
        "pm-utils"
        "system76-acpi-dkms"
        "system76-dkms"
        "system76-firmware-daemon"
        "system76-driver"
        "system76-io-dkms"
        "system76-oled"
        "system76-power"
        "system76-wallpapers"
# I might try using this some time....
#        "gnome-control-center-system76"
     )


# Install requirements that pacman can find first.
pacman -Syu bzrtp cmake doxygen bcunit jsoncpp rhash ortp python-pystache qt5-tools xerces xsd

function download_and_install() {
    # I'd like to give the parameter a decent name....
    package=$1
    base_url="https://aur.archlinux.org/cgit/aur.git/snapshot"
    
    # The directory SHOULDN'T exist, but just in case it does....
    if [ -d $package ]; then
        sudo rm -r $package
    fi

    wget "$base_url/$package.tar.gz"
    tar -xvf $package.tar.gz
    mv $package.tar.gz $package

    cd $package
    
    makepkg -s -i --noconfirm

    cd ..
    rm -rf $package
}

for pkg in ${pkgs[@]}; do
    download_and_install $pkg
done

# Start and enable any necessary services
sudo systemctl start system76.service
sudo systemctl start system76-firmware-daemon.service
sudo systemctl start system76-power.service

sudo systemctl enable system76.service
sudo systemctl enable system76-firmware-daemon.service
sudo systemctl enable system76-power.service

# Load the system76 module as well
sudo modprobe system76
