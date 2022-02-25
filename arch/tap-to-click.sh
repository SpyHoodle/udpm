#!/bin/sh

[ ! -f /etc/X11/xorg.conf.d/40-libinput.conf ] && sudo printf 'Section "InputClass"
  ¦ ¦ ¦ Identifier "libinput touchpad catchall"
  ¦ ¦ ¦ MatchIsTouchpad "on"
  ¦ ¦ ¦ MatchDevicePath "/dev/input/event*"
  ¦ ¦ ¦ Driver "libinput"
  # Enable left mouse button by tapping
  Option "Tapping" "on"
EndSection' | sudo tee -a /etc/X11/xorg.conf.d/40-libinput.conf
