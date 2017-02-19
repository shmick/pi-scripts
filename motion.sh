#!/bin/bash

# This script allows you to enable and disable Motion Detect alerts on the Amcrest security cam.  

CAM_USER="admin"
CAM_PASS="MySuperSecretPassword"
CAM_ADDR="127.0.0.1"

MotionDetect() {
    ENMODE="$1"
    curl -u $CAM_USER:$CAM_PASS "http://$CAM_ADDR/cgi-bin/configManager.cgi?action=setConfig&MotionDetect\[0\].Enable=$ENMODE"
}

case "$1" in
enable) MotionDetect true ;;
disable) MotionDetect false ;;
esac
