#!/bin/sh

newperms ()
{
  sudo sed -i "/#UDPM/d" /etc/sudoers
  sudo echo "$* #UDPM" | sudo tee -a /etc/sudoers
}

newperms "%wheel ALL=(ALL) ALL #UDPM
%wheel ALL=(ALL) NOPASSWD: /sbin/poweroff, /sbin/reboot, /sbin/shutdown"
