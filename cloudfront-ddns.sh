#!/bin/bash

# Requires curl and jq
# apt-get install -y curl jq

# This will be the primary domain to check against
pridomain="example.com"

# Get our current external IP
myip=$(dig +short myip.opendns.com @resolver1.opendns.com)

# Determine the CloudFlare DNS server for the primary domain
mycfdns=$(dig +short ns "$pridomain" @resolver1.opendns.com. | grep -m1 ns.cloudflare.com)
if [ "$?" -ne "0" ]
then
echo "$pridomain is not using CloudFlare for DNS"
exit 1
fi

# Query the CloudFlare DNS for the primary domain
curip=$(dig +short "$pridomain" @$mycfdns)

# Only attempt to update the DNS enrty if the IP has changed or
# the script has been run as "cloudfront-ddns.sh force"
if [ "$myip" != "$curip" ] || [ "$1" = "force" ]
then

cf_api="https://www.cloudflare.com/api_json.html"
cf_email="email.address"
cf_tkn="YourCloudFrontToken"
# List of domains, separated by a space
mydomains="example.com example.net"

for i in $mydomains
do
# Get the record ID of root A record
domain="$i"
rec_id=$(curl -s "$cf_api" \
-d "a=rec_load_all" \
-d "tkn=$cf_tkn" \
-d "email=$cf_email" \
-d "z=$domain" \
| jq --arg mydom "$domain" -r '.response.recs.objs[] | select(.type == "A" and .name == $mydom) | .rec_id')

curl -w "%{http_code}\\n" -o /dev/null -sq "$cf_api" \
-d "a=rec_edit" \
-d "tkn=$cf_tkn" \
-d "id=$rec_id" \
-d "email=$cf_email" \
-d "z=$domain" \
-d "type=A" \
-d "name=@" \
-d "content=$myip" \
-d "service_mode=0" \
-d "ttl=120"

done

fi
