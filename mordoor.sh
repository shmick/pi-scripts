#!/bin/bash
#
# mordoor.sh - Monitor and control the garage doors
# version=2015.07.10.r1
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

# Set this to false if you don't want to enable the auto close feature
AutoClose=true

# Default is 8:30PM till 7AM
# Set these to "0" if you always want it to check
StartTime="2030"
EndTime="700"

# How long the door is allowed to remain open during the hours of StartTime and EndTime
MaxMinutes="30"

# Don't change these unless you need to
NorthDoorStateFile="/ramdisk/ndstate"
SouthDoorStateFile="/ramdisk/sdstate"

NorthDoorLockFile="/var/tmp/ndLockFile"
SouthDoorLockFile="/var/tmp/sdLockFile"

NorthDoorClosing="/var/tmp/ndClosing"
SouthDoorClosing="/var/tmp/sdClosing"

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
if [[ -e $NorthDoorStateFile ]] && [[ -e $SouthDoorStateFile ]]

then 
	NdoorSTATE=$(cat $NorthDoorStateFile)

	if [ "$NorthStatus" = "0" ] && [ "$NdoorSTATE" = "1"  ]
	then
		NDoor="closed"
		echo 0 > $NorthDoorStateFile
		rm -f $NorthDoorLockFile

	elif [ "$NorthStatus" = "1" ] && [ "$NdoorSTATE" = "0"  ]
	then
		NDoor="open"
		echo 1 > $NorthDoorStateFile
	fi

	SDoorSTATE=$(cat $SouthDoorStateFile)

	if [ "$SouthStatus" = "0" ] && [ "$SDoorSTATE" = "1" ]
	then
		SDoor="closed"
		echo 0 > $SouthDoorStateFile
		rm -f $SouthDoorLockFile

	elif [ "$SouthStatus" = "1" ] && [ "$SDoorSTATE" = "0"  ]
	then
		SDoor="open"
		echo 1 > $SouthDoorStateFile
	fi

	NDoorAge=$(find $NorthDoorStateFile -mmin +$MaxMinutes)
	SDoorAge=$(find $SouthDoorStateFile -mmin +$MaxMinutes)
else
	if [[ -n "$NorthStatus" ]] || [[ -n "$SouthStatus" ]]
	then
		echo $NorthStatus > $NorthDoorStateFile
		echo $SouthStatus > $SouthDoorStateFile
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
LockFile="$NorthDoorLockFile" 
InUse="$NorthDoorClosing"
;;
south)
DoorStatus="$SouthStatus"
LockFile="$SouthDoorLockFile" 
InUse="$SouthDoorClosing"
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

# Sending a tweet is not enabled yet.
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
