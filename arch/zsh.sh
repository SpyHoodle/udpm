#!/bin/sh

sudo chsh -s /bin/zsh "$USER" >/dev/null 2>&1
sudo -u "$USER" mkdir -p "/home/$USER/.cache/zsh/"
