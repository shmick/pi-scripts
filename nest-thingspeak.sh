#!/bin/bash

sleep 5

TYPE="Content-Type: application/json"
TOKEN="X-THINGSPEAKAPIKEY: XXXXXXXXXXXXXXXX"
URL="https://api.thingspeak.com/update.json"

DATA=$(cat /ramdisk/nest-info.txt \
| grep -v -e "^G" -e "^I" \
| sed -e 's/A_OutsideTemp/field1/' \
-e 's/B_InsideTemp/field2/' \
-e 's/C_TargetTemp/field3/' \
-e 's/D_RelativeHumidity/field4/' \
-e 's/E_FurnaceOn/field5/' \
-e 's/F_AirConOn/field6/' \
-e 's/H_Battery/field7/' \
| awk '{print "\""$1"\":"$2}' \
| tr "\n" "," \
| sed 's/,$//g')
PAYLOAD=$(echo {"$DATA"})

curl -m 40 -o /dev/null -s -H "$TYPE" -H "$TOKEN" -d "$PAYLOAD" "$URL"
