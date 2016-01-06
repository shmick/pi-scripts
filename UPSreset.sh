#!/bin/bash
sudo $HOME/pi-scripts/usbreset /dev/bus/usb/$(lsusb | grep "Cyber Power" | awk '{print $2, $4}' | sed -e 's/://' -e 's/ /\//')
