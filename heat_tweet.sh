#!/bin/bash
# heat_tweet.sh 

# Ensure the Nest update script had time to fiinish
sleep 5

NESTDATA="/ramdisk/nest-info.txt"
HEATSTATEFILE="/ramdisk/heatstate"
COOLSTATEFILE="/ramdisk/coolstate"

TWEETCMD="python $HOME/pi-scripts/tweet.py"

if [[ -e $NESTDATA ]]

then

	HeatMode=$(grep FurnaceOn $NESTDATA | awk '{print $2}')
	CoolMode=$(grep AirConOn $NESTDATA | awk '{print $2}')
	OutsideTemp=$(grep OutsideTemp $NESTDATA | awk '{print $2}')
	InsideTemp=$(grep InsideTemp $NESTDATA | awk '{print $2}')
	TargetTemp=$(grep TargetTemp $NESTDATA | awk '{print $2}')
	Humidity=$(grep RelativeHumidity $NESTDATA | awk '{print $2}')
	RelHumid=$(grep OutsideHumidity $NESTDATA | awk '{print $2}')
	Time=$(date +%H:%M)

else
	echo "Sorry no datafile to read, exiting"
	exit
fi

CreateStatusAndTweet()
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

$TWEETCMD "$TweetString"
fi
}      

if [[ -e $HEATSTATEFILE ]] && [[ -e $COOLSTATEFILE ]]

then 
	HEATSTATE=$(cat $HEATSTATEFILE)

	if [ "$HeatMode" = "1" ] && [ "$HEATSTATE" = "0"  ]
	then
		Type=Heat
		Mode=ON
		echo 1 > $HEATSTATEFILE

	elif [ "$HeatMode" = "0" ] && [ "$HEATSTATE" = "1"  ]
	then
		Type=Heat
		Mode=OFF
		echo 0 > $HEATSTATEFILE
	fi

	COOLSTATE=$(cat $COOLSTATEFILE)

	if [ "$CoolMode" = "1" ] && [ "$COOLSTATE" = "0" ]
	then
		Type=AC
		Mode=ON
		echo 1 > $COOLSTATEFILE

	elif [ "$CoolMode" = "0" ] && [ "$COOLSTATE" = "1"  ]
	then
		Type=AC
		Mode=OFF
		echo 0 > $COOLSTATEFILE
	fi
fi

CreateStatusAndTweet
