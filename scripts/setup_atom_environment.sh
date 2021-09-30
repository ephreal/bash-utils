#!/bin/bash

sudo pip install pylama pylama-pylint flake8

mkdir ~/.atom
cp ../configfiles/atom.io/config.cson ~/.atom/

apm install atom-html-preview atom-latex busy-signal emmet intentions language-latex latex linter linter-ui-default linter-python linter-flake8 script atom-python-virtualenv
