#!/bin/bash

# Requires the following:
#
# 1: Nest info ( https://github.com/shmick/pi-scripts/get-nest-info.{sh,php}
#
# 2: Ouimeaux ( https://ouimeaux.readthedocs.org/en/latest/ )
#
# 3: JQ ( apt-get install jq # ( https://stedolan.github.io/jq/ )

OuimeauxURL=http://localhost:5000/api/device/
WeMoDevice="WeMo Christmas Tree"
UrlDevice=$(echo $WeMoDevice | sed 's/ /%20/g')

NestInfoFile=/ramdisk/nest-info.txt

if [ ! -f "$NestInfoFile" ]
then
exit 1
fi

DeviceState=$(curl -s ${OuimeauxURL}${UrlDevice} | jq '.state')

TargetTemp=$(awk '$1 ~ "TargetTemp" { print $2 }' $NestInfoFile)

case $TargetTemp in 
1.00)
NestStatus=Away
MODE=off
;;
*)
NestStatus=Home
MODE=on
;;
esac

WemoToggle () {
curl -s -o /dev/null -X POST ${OuimeauxURL}${UrlDevice}?state=$MODE
}

if [ "$NestStatus" = "Home" ] && [ "$DeviceState" = "0" ]
then
WemoToggle
elif [ "$NestStatus" = "Away" ] && [ "$DeviceState" = "1" ]
then
WemoToggle
fi
