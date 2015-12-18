#!/bin/bash

# Requires the following:
#
# 1: Nest info ( https://github.com/shmick/pi-scripts/get-nest-info.{sh,php}
#
# 2: Ouimeaux ( https://ouimeaux.readthedocs.org/en/latest/ )
#
# 3: JQ ( apt-get install jq ) // ( https://stedolan.github.io/jq/ )

Usage () {
echo "Usage: $0 [ on | off | auto ]"
}

OuimeauxURL=http://localhost:5000/api/device/
WeMoDevice="WeMo Christmas Tree"
UrlDevice=$(echo $WeMoDevice | sed 's/ /%20/g')
Cmd="$1"

GetState () {
NestInfoFile=/ramdisk/nest-info.txt

# Exit if the Nest info file to read home/away state is missing
if [ ! -f "$NestInfoFile" ]
then
echo "Unable to locate $NestInfoFile"
exit 1
fi

TargetTemp=$(awk '$1 ~ "TargetTemp" { print $2 }' $NestInfoFile)
TempReported="$?"

#Exit if no temp was reported
if [ $TempReported -eq 1 ]
then
exit 1
fi

# 0 = off, 1 = on
DeviceState=$(curl -s ${OuimeauxURL}${UrlDevice} | jq '.state')

# A target temp of 1.00 is reported by the Nest PHP API for Away Mode
case $TargetTemp in 
1.00)
NestStatus=Away
;;
*)
NestStatus=Home
;;
esac
}

WemoControl () {
curl -s -o /dev/null -X POST ${OuimeauxURL}${UrlDevice}\?state=${1}
}

case "$Cmd" in
on)
WemoControl on
;;
off)
WemoControl off
;;
auto)
GetState
if [ "$NestStatus" = "Home" ] && [ "$DeviceState" = "0" ]
then
WemoControl toggle
elif [ "$NestStatus" = "Away" ] && [ "$DeviceState" = "1" ]
then
WemoControl toggle
fi
;;
*)
Usage
;;
esac
