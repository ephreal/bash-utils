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
        "system76-firmware-daemon"
        "system76-driver"
        "system76-io-dkms"
        "system76-oled"
        "system76-power"
        "system76-wallpapers"
# I might try using this some time....
#        "gnome-control-center-system76"
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
}

function sudo_refresh() {
    # Gets forked to periodically run sudo -v. This prevents having to put in
    # your password from time to time.
    # Note that since this IS a slight security risk to leave running longer
    # than necessary, the script will clean up after itself IF it finishes
    # running normally. If CTRL+C was hit, then run cleanup.sh to finish
    # all cleanup for this script.

    # Refreshes once per minute. Max runtime is 60 minutes.
    for num in {1..60}; do
        sleep 60
        sudo -v
    done
}


# Place these inside a separate folder so I can delete them all at the end if I
# need. Not deleting them as I go along in case one of them fails to install
# for some reason. It's usually quicker to fix them that way.
mkdir packages
cd packages

# Prompt for sudo password to get this started
sudo -v

for pkg in ${pkgs[@]}; do

    # Start the sudo looping
    sudo_refresh &
    PID=$!
    PIDFILE="pidfile"

    # Create a pidfile in the packages dir just in case you need to check for
    # this afterwords
    echo $PID >> $PIDFILE

    # Install the package
    download_and_install $pkg


    # Cleanup the PIDFILE
    # Note that this runs ony final sleep after being killed, so don't be too
    # surprised to see it if you check for the PID right away. If it's still
    # running after 60 seconds, then there's a problem.
    # All tests have stopped before 60 seconds though.
    echo "Stopping sudo refresh on $PID"
    kill $PID
    rm $PIDFILE
done

cd ..

# Start and enable any necessary services
sudo systemctl start system76.service
sudo systemctl start system76-firmware-daemon.service
sudo systemctl start system76-power.service

sudo systemctl enable system76.service
sudo systemctl enable system76-firmware-daemon.service
sudo systemctl enable system76-power.service

# Load the system76 module as well
sudo modprobe system76
