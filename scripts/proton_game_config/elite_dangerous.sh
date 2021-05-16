# Note: This does not get elite dangerous playable.... yet.

echo "\n\nWARNING: Ensure that you have installed Elite Dangerous First!"
echo "This WILL NOT work properly unless the wine prefix for Elite Dangerous"
echo "has been created, and the easiest wat to do that is to install it."
echo "Press enter to continue.\n\n"

read

packages="corefonts dotnet40 vcrun2012 quartz dotnet472"
# Used for when I need to test individual package installation.
#packages="dotnet472"

# I'm using wintricks rather than protontricks because protontricks fails to install anything for some reason.
# It's possible the wineprefix that elite installed to has something wrong with it. This seems unlikely as 
# winetricks is able to install just fine.
WINEPREFIX="$HOME/.steam/steam/steamapps/compatdata/359320" winetricks -q $packages
WINEPREFIX="$HOME/.steam/steam/steamapps/compatdata/359320" winetricks win10
