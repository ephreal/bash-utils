#!/bin/bash

# This downloads and installs the AUR packages that I use on a regular basis.


pkgs=(
        "tor-browser"
        "expressvpn"
        "expressvpn-gui"
        "minecraft-launcher"
        "plex-media-player"
     )


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
