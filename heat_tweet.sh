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

LATESTINFO=$(cat $NESTDATA)

        HeatOn=$(echo "$LATESTINFO" | grep E_FurnaceOn.*1$)
	HeatOff=$(echo "$LATESTINFO" | grep E_FurnaceOn.*0$)
	CoolOn=$(echo "$LATESTINFO" | grep F_AirConOn.*1$)
	CoolOff=$(echo "$LATESTINFO" | grep F_AirConOn.*0$)
	OutsideTemp=$(echo "$LATESTINFO" | grep A_OutsideTemp | awk '{print $2}')
	InsideTemp=$(echo "$LATESTINFO" | grep B_InsideTemp | awk '{print $2}')
	TargetTemp=$(echo "$LATESTINFO" | grep C_TargetTemp | awk '{print $2}')
	Humidity=$(echo "$LATESTINFO" | grep D_RelativeHumidity | awk '{print $2}')
	RelHumid=$(echo "$LATESTINFO" | grep I_OutsideHumidity | awk '{print $2}')
	Time=$(date +%H:%M)

else
	echo "Sorry no datafile to read, exiting"
	exit
fi

gentweet()
{
TweetString="$Type $Mode at ${Time}, \
Target = $TargetTemp°C, \
Inside = $InsideTemp°C, \
Outside = $OutsideTemp°C, \
Outside RH = $RelHumid%, \
Inside RH = $Humidity% \
"
}      

if [[ -e $HEATSTATEFILE ]]

then 
	HEATSTATE=$(cat $HEATSTATEFILE)

	if [ "$HeatOn" != "" ] && [ "$HEATSTATE" = 0  ]
	then
		Type=Heat
		Mode=ON
		gentweet
		$TWEETCMD "$TweetString"

	elif [ "$HeatOff" != "" ] && [ "$HEATSTATE" = 1  ]
	then
		Type=Heat
		Mode=OFF
		gentweet
		$TWEETCMD "$TweetString"
	fi

	COOLSTATE=$(cat $COOLSTATEFILE)

	if [ "$CoolOn" != "" ] && [ "$COOLSTATE" = 0  ]
	then
		Type=AC
		Mode=ON
		gentweet
		$TWEETCMD "$TweetString"

	elif [ "$CoolOff" != "" ] && [ "$COOLSTATE" = 1  ]
	then
		Type=AC
		Mode=OFF
		gentweet
		$TWEETCMD "$TweetString"
	fi
fi

#  Update the statefiles

if [[ "$HeatOn" != "" ]]
then
	echo 1 > $HEATSTATEFILE

elif [[ "$HeatOff" != "" ]]
then
	echo 0 > $HEATSTATEFILE

fi

if [[ "$CoolOn" != "" ]]
then
	echo 1 > $COOLSTATEFILE

elif [[ "$CoolOff" != "" ]]
then
	echo 0 > $COOLSTATEFILE
fi
