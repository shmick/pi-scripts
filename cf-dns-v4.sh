#!/bin/bash

# Requires: curl and jq
# apt-get install -y curl jq

# This script will attempt to update the host entry
# ddns.example.com on CloudFlare
#
# You need to first make sure that you have an A record
# for ddns.example.com CloudFlare
#

config=~/.cf_ddns

if [ -f $config ]
then
source $config
else
echo "Config file $config not found"
exit 1
fi

#Your config file should contain:
#..........This will be the primary domain to check against
# pridomain="example.com"
#..........This the full list of domains to check against
# mydomains="$pridomain example.net example.org"
#..........Your CloudFlare email address
# cf_email="you@example.com"
#..........Your CloudFlare Global API Key
# cf_tkn="12345678901234567890"
#..........Your ddns hostname, by default we use "ddns"
# ddnshost="ddns"

# Determine the CloudFlare DNS server for the primary domain
mycfdns=$(dig +short ns "$pridomain" @resolver1.opendns.com. | grep -m1 ns.cloudflare.com)
if [ "$?" -ne "0" ]
then
echo "$pridomain does not appear to be using using CloudFlare for DNS"
exit 1
fi

# Query the CloudFlare DNS for the primary domain
curip=$(dig +short "$pridomain" @$mycfdns)

# Get our current external IP
myip=$(dig +short myip.opendns.com @resolver1.opendns.com)

	if [ "$myip" != "$curip" ] || [ "$1" = "force" ]
	then

	cf_api="https://api.cloudflare.com/client/v4/"

	for i in $mydomains
	do

	domain=$i
	ddns=$ddnshost.$domain

# Get the zone ID
	zoneid=$(curl -s "$cf_api/zones?name=$domain" \
			-H "X-Auth-Email: $cf_email" \
			-H "X-Auth-Key: $cf_tkn" \
			-H "Content-Type: application/json" \
			| jq -r '.result[0].id')

# Get the record ID
	recid=$(curl -s "$cf_api/zones/$zoneid/dns_records?type=A&name=$ddns" \
			-H "X-Auth-Email: $cf_email" \
			-H "X-Auth-Key: $cf_tkn" \
			-H "Content-Type: application/json" \
			| jq -r '.result[0].id')

# Update the record
	curl -s -o /dev/null -X PUT "$cf_api/zones/$zoneid/dns_records/$recid" \
		-H "X-Auth-Email: $cf_email" \
		-H "X-Auth-Key: $cf_tkn" \
		-H "Content-Type: application/json" \
		-d '{"id":"'$recid'","type":"A","name":"'$ddns'","ttl":"120","content":"'$myip'"}'

	done

	fi
