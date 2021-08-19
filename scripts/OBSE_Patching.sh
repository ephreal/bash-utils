# Make a backup of the original launchers.

cp obse_loader.exe obse_loader.exe.bak
cp OblivionLauncher.exe OblivionLauncher.exe.bak

# Patch by removing OBSE's complaint about the steam version
printf '\x90\x90\x90' | dd conv=notrunc of=obse_loader.exe bs=1 seek=$((0x14cb))

# Set the launcher to run obse directly.
printf 'obse_loader\x00' | dd conv=notrunc of=OblivionLauncher.exe bs=1 seek=$((0x1347c))

echo "OBSE and the Oblivion Launcher are patched. Try running the game from steam now."
