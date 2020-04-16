#!/bin/bash

# This downloads and installs wine-valve-git from the AUR. Because I
# have had some issues with installation, this is installing additional
# packages as well. This also brings installs proton as it's commonly
# used with win-valve-git
#
# This also installs libraries needed to have steam work properly with
# proton.

# A list of what packages are needed in order to install wine-valve-git
pkgs=(
      "spirv-headers-git"
      "lib32-spirv-tools"
       "vkd3d-valve-git"
       "lib32-vkd3d-valve-git"
       "wine-valve-git"
       "proton"
       "python-vdf"
       "protontricks"
     )

# Libraries needed to make steam work with proton
LIBS="lib32-libnm-glib lib32-libvdpau lib32-libudev0-shim libudev0-shim"

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

sudo pacman -Sy $LIBS --noconfirm
