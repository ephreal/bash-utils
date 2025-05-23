if [ ! -d $HOME/.steam/steam/compatibilitytools.d ]; then
    mkdir -p $HOME/.steam/steam/compatibilitytools.d
fi

cd $HOME/.steam/steam/compatibilitytools.d

# Note: For Magicka, I use Proton 4.2.9, no GE version.

# Glorious Eggroll Versions that I use. I'll make it pull from the array in the
# future. For now, I just want to hack this together so it works.
versions=(
    "7.2-GE-2" # Cyberpunk 2077
    "5.6-GE-2" # Assassin's Creed (all of them), Satisfactory, Oblivion
    "5.4-GE-3" # Deep Rock Galactic
    "5.2-GE-2" # Dishonored, Dishonored 2
)


# Note: These new versions are versions that use the new naming scheme for proton

newversions=(
    "8-3"
    "9-11" # Warframe - Known Working
    "9-22" # Warframe - Experimental
)

# This is how I would prefer to have these run... that way all I need to do is
# add a particular GE version up top if I ever need them.

for ge_version in ${versions[@]}; do

    if [ ! -d Proton-$ge_version ]; then
        echo "\n\nInstalling Proton-$ge_version\n\n"
        wget https://github.com/GloriousEggroll/proton-ge-custom/releases/download/$ge_version/Proton-$ge_version.tar.gz
        tar -xvf Proton-$ge_version.tar.gz
        rm Proton-$ge_version.tar.gz
    fi

done


for ge_version in ${newversions[@]}; do
    if [ ! -d "GE-Proton$ge_version" ]; then
        echo "\n\nInstalling GE-Proton$ge_version\n\n"
        wget https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton$ge_version/GE-Proton$ge_version.tar.gz
        tar -xvf GE-Proton$ge_version.tar.gz
        rm GE-Proton$ge_version.tar.gz
    fi
done
