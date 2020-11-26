if [ ! -d $HOME/.steam/steam/compatibilitytools.d ]; then
    mkdir -p $HOME/.steam/steam/compatibilitytools.d
fi

cd $HOME/.steam/steam/compatibilitytools.d

# Glorious Eggroll Versions that I use. I'll make it pull from the array in the
# future. For now, I just want to hack this together so it works.
versions=(
    "5.21-GE-1" # Warframe
    "5.6-GE-2" # Assassin's Creed (all of them)
    "5.4-GE-3" # Deep Rock Galactic
    "5.2-GE-2" # Dishonored, Dishonored 2
)

# Warframe
if [ ! -d Proton-5.21-GE-1 ]; then
    wget https://github.com/GloriousEggroll/proton-ge-custom/releases/download/5.21-GE-1/Proton-5.21-GE-1.tar.gz
    tar -xvf Proton-5.21-GE-1.tar.gz
    rm Proton-5.21-GE-1.tar.gz
fi

# Assassin's creed (all of them currently)
if [ ! -d Proton-5.6-GE-2 ]; then
    wget https://github.com/GloriousEggroll/proton-ge-custom/releases/download/5.6-GE-2/Proton-5.6-GE-2.tar.gz
    tar -xvf Proton-5.6-GE-2.tar.gz
    rm Proton-5.6-GE-2.tar.gz
fi

# Deep rock galactic
if [ ! -d Proton-5.4-GE-3 ]; then
    wget https://github.com/GloriousEggroll/proton-ge-custom/releases/download/5.4-GE-3/Proton-5.4-GE-3.tar.gz
    tar -xvf Proton-5.4-GE-3.tar.gz
    rm Proton-5.4-GE-3.tar.gz
fi

# Dishonored, Dishonored 2
if [ ! -d Proton-5.2-GE-2 ]; then
    wget https://github.com/GloriousEggroll/proton-ge-custom/releases/download/5.2-GE-2/Proton-5.2-GE-2.tar.gz
    tar -xvf Proton-5.2-GE-2.tar.gz
    rm Proton-5.2-GE-2.tar.gz
fi
