#!/bin/sh

sudo rmmod pcspkr
sudo echo "blacklist pcspkr" | sudo tee -a /etc/modprobe.d/nobeep.conf
