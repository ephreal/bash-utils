mkdir -p $HOME/.local/share/systemd/user
cp ../gnome_inspirobot_background/* $HOME/.local/share/systemd/user
sed -i "s%HOME%$HOME%g" $HOME/.local/share/systemd/user/background.service
systemctl --user enable background.service

# Set the first random background immediately
systemctl --user start background.service
