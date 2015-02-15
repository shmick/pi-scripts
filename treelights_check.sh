#!/bin/bash

WEMODEVICE="Christmas Tree"

WemoToggle () {
curl -s -o /dev/null -X POST http://localhost:5000/api/device/WeMo%20Christmas%20Tree?state=$MODE
}

READFILE=/ramdisk/nest-info.txt

if [ ! -f "$READFILE" ]
then
exit 1
fi

STATE=$(curl -s http://localhost:5000/api/device/WeMo%20Christmas%20Tree | grep state)
STATE_ON=$(echo $STATE | grep 1)
STATE_OFF=$(echo $STATE | grep 0)

AWAY=$(grep C_TargetTemp $READFILE | awk '{print $2}' | grep ^1.00)

if [ "$AWAY" = "1.00" ]
then STATUS=Away
MODE=off
else
STATUS=Home
MODE=on
fi

if [ "$STATUS" = "Home" ]
then
	if [ "$STATE_ON" = "" ]
	then
	WemoToggle
	fi
elif [ "$STATUS" = "Away" ]
then
	if [ "$STATE_OFF" = "" ]
	then
	WemoToggle
	fi
fi
