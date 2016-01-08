#!/bin/bash

RTLP="/usr/local/bin/rtl_power"

FREQ_START="566M"
FREQ_END="608M"
STEP="10k"
GAIN="50"
INTERVAL="5"
MINUTES="30m"

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
filenum
$RTLP -f $FREQ_START:$FREQ_END:$STEP -g $GAIN -i $INTERVAL -e $MINUTES $LOG
done
