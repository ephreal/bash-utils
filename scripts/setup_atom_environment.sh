#!/bin/bash

sudo pip install pylama pylama-pylint flake8

mkdir ~/.atom
cp ../configfiles/atom.io/config.cson ~/.atom/

apm install atom-html-preview busy-signal emmet intentions linter linter-ui-default linter-python linter-flake8 script atom-python-virtualenv
