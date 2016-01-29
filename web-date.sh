#!/bin/bash
# Add FQDNs or IPs in here
HOSTS="www.nrc-cnrc.gc.ca google.com amazon.com"
for host in $HOSTS
do 
DATE="$(curl -m 3 -Is http://${host} | grep "^Date:" | sed 's/^Date: //' | grep " 20[0-9][0-9] ")"
while  [ $? -eq 0 ]
	do
	sudo date -s "$DATE" > /dev/null
	sudo hwclock --systohc
	exit 0
	done
done
