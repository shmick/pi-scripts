#!/bin/bash
#
# Monitor and control the garage doors
#
# Requires WebIOPi // https://code.google.com/p/webiopi/
#
# 0 = closed
# 1 = open
#
# Check https://github.com/shmick/pi-scripts/ for latest version
#
# Twitter: @shmick

WebIOPi=$(curl -vs -m 3 -o /dev/null http://localhost:8000/ 2>&1 | grep "200 OK")
if [ -z "$WebIOPi" ]
then
echo "sorry, WebIOPi doesn't appear to be running"
exit 1
fi

# How long the door is allowed to remain open during the hours of
# StartTime and EndTime
MaxMinutes="30"

# Set this to false if you don't want to enable the auto close feature
AutoClose=true

# StartTime in HHMM format
# Default is 8:30PM till 7AM
# Set these to "0" if you always want it to check
StartTime="2030"
EndTime="700"

NDoorSTATEFILE="/ramdisk/ndstate"
SDoorSTATEFILE="/ramdisk/sdstate"

NDoorLOCKFILE="/var/tmp/ndlock"
SDoorLOCKFILE="/var/tmp/sdlock"

NDoorINUSE="/var/tmp/ndINUSE"
SDoorINUSE="/var/tmp/sdINUSE"



TWEETCMD="python $HOME/pi-scripts/tweet.py"


DoorStatus()
{
	NorthStatus=$(curl -s http://localhost:8000/garage/north/status)
	SouthStatus=$(curl -s http://localhost:8000/garage/south/status)
}

GatherData()
{
	DoorStatus
	HourMin=$(date +%_H%M)
	Time=$(date +%H:%M)
	TweetString=""
	Type=""
	Mode=""
}

StateCheckAndUpdate()
{
if [[ -e $NDoorSTATEFILE ]] && [[ -e $SDoorSTATEFILE ]]

then 
	NdoorSTATE=$(cat $NDoorSTATEFILE)

	if [ "$NorthStatus" = "0" ] && [ "$NdoorSTATE" = "1"  ]
	then
		NDoor="closed"
		echo 0 > $NDoorSTATEFILE
		rm -f $NDoorLOCKFILE

	elif [ "$NorthStatus" = "1" ] && [ "$NdoorSTATE" = "0"  ]
	then
		NDoor="open"
		echo 1 > $NDoorSTATEFILE
	fi

	SDoorSTATE=$(cat $SDoorSTATEFILE)

	if [ "$SouthStatus" = "0" ] && [ "$SDoorSTATE" = "1" ]
	then
		SDoor="closed"
		echo 0 > $SDoorSTATEFILE
		rm -f $SDoorLOCKFILE

	elif [ "$SouthStatus" = "1" ] && [ "$SDoorSTATE" = "0"  ]
	then
		SDoor="open"
		echo 1 > $SDoorSTATEFILE
	fi

	NDoorAge=$(find $NDoorSTATEFILE -mmin +$MaxMinutes)
	SDoorAge=$(find $SDoorSTATEFILE -mmin +$MaxMinutes)
else
	if [[ -n "$NorthStatus" ]] || [[ -n "$SouthStatus" ]]
	then
		echo $NorthStatus > $NDoorSTATEFILE
		echo $SouthStatus > $SDoorSTATEFILE
	fi
fi
}

CheckAutoClose() 
{
if [ "$AutoClose" = "true" ]
then
AutoClose
fi
}

AutoClose() 
{
if [ "$HourMin" -gt "$StartTime" ] || [ "$HourMin" -lt "$EndTime" ]
then
	if [ -n "$NDoorAge" ] && [ "$NorthStatus" = "1" ]
	then
	echo "Close the North door"
	CloseDoor north
	fi

	if [ -n "$SDoorAge" ] && [ "$SouthStatus" = "1" ]
	then
	echo "Close the South door"
	CloseDoor south
	fi
fi
}

SelectDoor()
{
case $1 in
north)
DoorStatus="$NorthStatus" 
LockFile="$NDoorLOCKFILE" 
InUse="$NDoorINUSE"
;;
south)
DoorStatus="$SouthStatus"
LockFile="$SDoorLOCKFILE" 
InUse="$SDoorINUSE"
;;
esac
}

CloseDoor()
{
SelectDoor $@

if [ -f $LockFile ] || [ -f $InUse ]
then
exit 1
fi

touch $InUse
count=1
while [ $count -le 3 ] && [ $DoorStatus = 1 ]
do
curl -d "" http://localhost:8000/garage/$1/button
sleep 20
(( count ++ ))
DoorStatus
SelectDoor $@
done

if [ $DoorStatus = 1 ]
then
touch $LockFile
else
rm -f $InUse
fi

}

CreateTweet()
{
if [ "$Type" = "" ]
then
	exit
else
	TweetString="$Type $Mode at ${Time}, \
	Target = $TargetTemp°C, \
	Inside = $InsideTemp°C, \
	Outside = $OutsideTemp°C, \
	Outside RH = $RelHumid%, \
	Inside RH = $Humidity% \
	"
fi
}

SendTweet()
{
if [ "$TweetString" = "" ]
then
	exit
else
	$TWEETCMD "$TweetString"
fi
}      

GatherData
StateCheckAndUpdate
#CreateTweet
#SendTweet
CheckAutoClose
