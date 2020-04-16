#!/bin/bash

# This downloads and installs all system76 packages from the archlinux AUR
# that I'd like to have. This could easily be adapted to install any AUR
# package provided the dependencies install without requiring an AUR package
# as a dependency.

# This is split into it's own separate file as not every device I have comes
# from system76.

# Package list of all system76 packages I'd like
pkgs=(
        "firmware-manager-git"
        "pm-utils"
        "system76-acpi-dkms"
        "system76-dkms"
        "system76-driver"
        "system76-firmware-daemon"
        "system76-io-dkms"
        "system76-oled"
        "system76-power"
        "system76-wallpapers"
     )


# Install a useful package for system76-driver before continuing
pacman -S xorg-xbacklight

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
    rm -r $package
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
