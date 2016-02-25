#!/bin/bash

# Requires: curl and jq
# apt-get install -y curl jq

# This script will attempt to update the host entry
# ddns.example.com on CloudFlare
#
# You need to first make sure that you have an A record
# for ddns.example.com CloudFlare
#
# Change the below to your own info

# This will be the primary domain to check against
pridomain="example.com"

# This the full list of domains to check against
mydomains="$pridomain example.net example.org"

# Your CloudFlare email address
cf_email="you@example.com"

# Your CloudFlare Global API Key
cf_tkn="12345678901234567890"

# Your ddns hostname, by default we use "ddns"
ddnshost="ddns"

# END OF CONFIG OPTIONS

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
# 
if [ "$myip" != "$curip" ] || [ "$1" = "force" ]
then
cf_api="https://www.cloudflare.com/api_json.html"
    for i in $mydomains
    do
    # Get the record ID of the $ddnshost A record
    domain="$i"
    rec_id=$(curl -s "$cf_api" \
    -d "a=rec_load_all" \
    -d "tkn=$cf_tkn" \
    -d "email=$cf_email" \
    -d "z=$domain" \
    | jq --arg ddns "$ddnshost.$domain" -r '.response.recs.objs[] | select(.type == "A" and .name == $ddns) | .rec_id')

    curl -w "%{http_code}\\n" -o /dev/null -sq "$cf_api" \
    -d "a=rec_edit" \
    -d "tkn=$cf_tkn" \
    -d "id=$rec_id" \
    -d "email=$cf_email" \
    -d "z=$domain" \
    -d "type=A" \
    -d "name=$ddnshost" \
    -d "content=$myip" \
    -d "service_mode=0" \
    -d "ttl=120"
    done
fi
