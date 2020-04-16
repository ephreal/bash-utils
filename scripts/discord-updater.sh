#!/bin/bash

# Get sudo privileges for later.
# Note: only works if immediate timeout of sudo privileges is not enabled.
# If the timeout is immediate, just comment this next line out.
sudo echo ""

# The directory SHOULDN'T exist, but just in case it does....
if [ -d "discord-canary" ]; then
    sudo rm -r "discord-canary"
fi

# Download, extract, and install discord-canary from aur.archlinux.org
wget https://aur.archlinux.org/cgit/aur.git/snapshot/discord-canary.tar.gz
tar -xvf discord-canary.tar.gz
mv discord-canary.tar.gz discord-canary
cd discord-canary
makepkg -s --noconfirm -i

# Cleanup
cd ..
sudo rm -r discord-canary
