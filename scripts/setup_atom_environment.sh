#!/bin/bash

sudo pip install pylama pylama-pylint flake8

mkdir ~/.atom
cp ../configfiles/atom.io/config.cson ~/.atom/

apm install busy-signal
apm install intentions
apm install linter
apm install linter-ui-default
apm install linter-python
apm install linter-flake8
apm install script
apm install atom-python-virtualenv
