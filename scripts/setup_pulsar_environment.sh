#!/bin/bash

# Atom.io is dead, long live pulsar!

# For non-archlinux distros, install the following packages through pip
# sudo pip install pylama pylama-pylint flake8

# Install these packages on arch
sudo pacman -Syu pylama python-pylint flake8

# Ensure the .pulsar directory exists
mkdir ~/.pulsar
cp ../configfiles/pulsar/config.cson ~/.pulsar/

pulsar --package install atom-html-preview atom-latex busy-signal emmet intentions language-latex latex linter linter-ui-default linter-python linter-flake8 script atom-python-virtualenv
