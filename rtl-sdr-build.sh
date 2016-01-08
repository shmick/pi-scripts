#!/bin/bash

sudo apt-get update
sudo apt-get install -y libusb-1.0-0-dev pkg-config ca-certificates git-core cmake build-essential --no-install-recommends
sudo apt-get clean

echo 'blacklist dvb_usb_rtl28xxu' | sudo tee /etc/modprobe.d/raspi-blacklist.conf > /dev/null
git clone git://git.osmocom.org/rtl-sdr.git 
mkdir rtl-sdr/build 
cd rtl-sdr/build 
cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON 
make 
sudo make install
