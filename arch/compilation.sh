#!/bin/sh

sudo sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf
