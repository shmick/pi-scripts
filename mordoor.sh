#!/bin/bash
# mordoor.sh - Monitor and control the garage doors
# version=2015.07.12.r1
#
# Requires WebIOPi // https://code.google.com/p/webiopi/
#
# Check https://github.com/shmick/pi-scripts/ for latest version
#
# https://twitter.com/shmick 
# email: mordoor/ww0/ca 

WebIOPiURL="http://localhost:8000"

WebIOPiStatus=$(curl -s -o /dev/null -w "%{http_code}" $WebIOPiURL)
if [ "$WebIOPiStatus" != "200" ]
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

# Change to "@whateveryouwant" to send a tweet
TweetTo=""

# Don't change these unless you need to
TMPDIR="/var/tmp"
NorthDoorStateFile="$TMPDIR/ndstate"
SouthDoorStateFile="$TMPDIR/sdstate"
NorthDoorLockFile="$TMPDIR/ndLockFile"
SouthDoorLockFile="$TMPDIR/sdLockFile"
NorthDoorClosing="$TMPDIR/ndClosing"
SouthDoorClosing="$TMPDIR/sdClosing"
NorthDoorTweet="$TMPDIR/ndTweet"
SouthDoorTweet="$TMPDIR/sdTweet"

TWEETCMD="python $HOME/pi-scripts/tweet.py"

DoorStatus()
{
	NorthStatus=$(curl -s "$WebIOPiURL"/garage/north/status)
	SouthStatus=$(curl -s "$WebIOPiURL"/garage/south/status)

	# Give the status codes useable names
	# 0 = closed, 1 = open
	case $NorthStatus in
	0) NorthStatus=closed ;; 1) NorthStatus=open ;;
	esac
	case $SouthStatus in
	0) SouthStatus=closed ;; 1) SouthStatus=open ;;
	esac
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
# If the North and Sputh state files exist on the filesystem
# compare them to the latest status of the doors and update them
# only if the state has changed.
if [ -e $NorthDoorStateFile ] && [ -e $SouthDoorStateFile ]

then 
	NdoorSTATE=$(cat $NorthDoorStateFile)

	if [ "$NorthStatus" = "closed" ] && [ "$NdoorSTATE" = "open"  ]
	then
		echo closed > $NorthDoorStateFile
		# If the door has changed from open to closed then
		# delete the lockfile that prevents the auto close
		# routine from running after a failed close attempt
		RemoveLocks north

	elif [ "$NorthStatus" = "open" ] && [ "$NdoorSTATE" = "closed"  ]
	then
		echo open > $NorthDoorStateFile
	fi

	SDoorSTATE=$(cat $SouthDoorStateFile)

	if [ "$SouthStatus" = "closed" ] && [ "$SDoorSTATE" = "open" ]
	then
		echo closed > $SouthDoorStateFile
		# If the door has changed from open to closed then
		# delete the lockfile that prevents the auto close
		# routine from running after a failed close attempt
		RemoveLocks south

	elif [ "$SouthStatus" = "open" ] && [ "$SDoorSTATE" = "closed"  ]
	then
		echo open > $SouthDoorStateFile
	fi

	NDoorAge=$(find $NorthDoorStateFile -mmin +$MaxMinutes)
	SDoorAge=$(find $SouthDoorStateFile -mmin +$MaxMinutes)
else
	# Create the North and South state files based on the current status
	# of each door
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
if [ "$HourMin" -ge "$StartTime" ] || [ "$HourMin" -le "$EndTime" ]
then
	if [ -n "$NDoorAge" ] && [ "$NorthStatus" = "open" ]
	then
	CloseDoor north
	fi

	if [ -n "$SDoorAge" ] && [ "$SouthStatus" = "open" ]
	then
	CloseDoor south
	fi
fi
}

RemoveLocks()
{
case $1 in
north)
LockFile="$NorthDoorLockFile"
TweetFile="$NorthDoorTweet"
;;
south)
LockFile="$SouthDoorLockFile" 
TweetFile="$SouthDoorTweet"
;;
esac
rm -f $LockFile $TweetFile
}

SelectDoor()
{
case $1 in
north)
DoorName="North"
DoorState="$NorthStatus" 
LockFile="$NorthDoorLockFile" 
InProgress="$NorthDoorClosing"
TweetFile="$NorthDoorTweet"
;;
south)
DoorName="South"
DoorState="$SouthStatus"
LockFile="$SouthDoorLockFile" 
InProgress="$SouthDoorClosing"
TweetFile="$SouthDoorTweet"
;;
esac
}

CloseDoor()
{
SelectDoor $@

# If a lockfile exists from a previously failed close attemp
# or a door close is currently in progress, dont do anything
if [ ! -f $LockFile ] || [ ! -f $InProgress ]
then
	touch $InProgress
	count=1
	while [ $count -le 3 ] && [ "$DoorState" = "open" ]
	do
	curl -o /dev/null -d "" $WebIOPiURL/garage/$1/button
	sleep 20
	(( count ++ ))
	DoorStatus
	SelectDoor $@
	done
	rm -f $InProgress

	# If the door is still open, write out a lockfile to prevent
	# the door from being auto closed again. The lockfile will be
	# removed once the door has returned to a closed state
	if [ "$DoorState" = "open" ]
	then
	touch $LockFile
	SendTweet
	fi
fi
}

SendTweet()
{
# Send a tweet only once. The TweetFile will also be removed once the
# door has returned to a closed state.
if [ ! -f "$TweetFile" ]
then
	TweetString="ERROR: Unable to auto close $DoorName door at ${Time} $TweetTo" 
	$TWEETCMD "$TweetString"
	touch $TweetFile
fi
}      

GatherData
StateCheckAndUpdate
CheckAutoClose
