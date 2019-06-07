#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'

# My aliases defined here
alias pacman='sudo pacman'

PS1='[\u@\h \W]\$ '
