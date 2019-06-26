SAVE_PATH="$HOME/.local/share/systemd/user/background.jpg"

rm $SAVE_PATH
wget -O $SAVE_PATH `curl https://inspirobot.me/api?generate=true`
gsettings set org.gnome.desktop.background picture-uri file://$SAVE_PATH

