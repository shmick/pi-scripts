#!/bin/bash

rtlcheck() {
# Exit if an RTL device isn't found
RTLDEVICE="$(cat  /sys/bus/usb/devices/*/product | grep RTL)"
if [ "$?" -ne 0 ]
then
exit $?
fi
}

rtlcheck

RTLP="/usr/local/bin/rtl_power"

# Senn G Band
FREQ_START="566M"
FREQ_END="608M"

# MiPro 
#FREQ_START="620M"
#FREQ_END="644M"

STEP="10k"
GAIN="35"
INTERVAL="5"

filenum () {
LASTFILE=$(ls $HOME/scans | tail -1 | grep "scan-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9].log") 

if [ "$?" -ge 1 ]
then
FILENUM="100000000"
else
LASTNUM="$(basename $LASTFILE .log | awk -F- '{print $2}')"
FILENUM="$(( LASTNUM + 1 ))"
fi
LOG="${HOME}/scans/scan-${FILENUM}.log"
}

while true
do
rtlcheck
filenum
$RTLP -f $FREQ_START:$FREQ_END:$STEP -g $GAIN -i $INTERVAL $LOG
done
