#!/bin/bash

# Fields
#1 battery.charge:
#2 battery.voltage:
#3 input.voltage:
#4 input.voltage.nominal:
#5 output.voltage:
#6 ups.load:
#7 battery.runtime:

UPSNAME=Basement_UPS
HOST=localhost

UPSINFO1=$(upsc $UPSNAME@$HOST \
| grep \
-e battery.charge: \
-e battery.voltage: \
-e input.voltage: \
-e input.voltage.nominal: \
-e output.voltage: \
-e ups.load: \
| awk -F: '{print $2}')

# The default output of battery.runtime is in seconds
# Get the battery.runtime info and then divide by 60
# to convert seconds to minutes
UPSINFO2=$(upsc $UPSNAME@$HOST battery.runtime)
UPSINFO2=$(( UPSINFO2/60 ))

UPSINFO=$(echo $UPSINFO1 $UPSINFO2)

if [ -z "$UPSINFO" ]
then
echo "Sorry, no data from upsc"
exit
fi

n=1

JSON=$(echo "{"
for i in $UPSINFO
do echo "\"field$n\":$i,"
(( n++ ))
done
echo "}")

TYPE="Content-Type: application/json"
TOKEN="X-THINGSPEAKAPIKEY: XXXXXXXXXXXXXXX7"
URL="https://api.thingspeak.com/update.json"
PAYLOAD=$(echo $JSON | sed 's/, }/ }/')

curl -m 40 -o /dev/null -s -H "$TYPE" -H "$TOKEN" -d "$PAYLOAD" "$URL"
