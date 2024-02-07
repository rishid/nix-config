#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Automatically update your CloudFlare DNS record to the IP, Dynamic DNS

API="https://api.cloudflare.com/client/v4"
TOKEN="$CF_DNS_API_TOKEN" # from secrets
CACHE_FILE="/tmp/cf-ddns-wan-ip.txt"

# Main function
function main {
  # Required env variables
  [ -z ${TOKEN+x} ] && echo "Error: missing TOKEN" && return 1
  [ -z ${FQDN+x} ] && echo "Error: missing FQDN" && return 1

  DOMAIN=$(hostname -d "$FQDN")

  # Get public IP address from Cloudflare
  ip="$(dig +short txt ch whoami.cloudflare @1.0.0.1 | tr -d \")"

  # Check if public IP doesn't match the cached IP
  if [[ "$(cat "$CACHE_FILE" 2>/dev/null)" != "$ip" ]]; then
    update_dns_records "$ip"

    echo "$ip" > "$CACHE_FILE"
    echo "Updated IP address to $ip"
  else
    echo "IP address unchanged, no update needed"
  fi
}

# Update DNS records
function update_dns_records {
  local contents="$1"
  local type="A"
  local cfzone_id
  local cfrecord_id
  cfzone_id=$(http --check-status -A bearer -a $TOKEN \
      GET "$API/zones" \
      "name==$DOMAIN" | jq -r '.result[0].id' )

  cfrecord_id=$(http --check-status -A bearer -a $TOKEN \
    GET "$API/zones/$cfzone_id/dns_records" \
    "type==$type" "name==$FQDN" | jq -r '.result[0].id')

  # Record doesn't yet exist
  if [ "$cfrecord_id" = "null" ]; then
    # Create new record
    http -q --check-status -A bearer -a $TOKEN \
      POST "$API/zones/$cfzone_id/dns_records" \
      type="$type" \
      name="$FQDN" \
      content="$contents" \
      ttl:=1 \
      proxied:=false \
      comment="ddns"

  # Record already exists
  else
    # Update existing record
    http -q --check-status -A bearer -a $TOKEN \
      PATCH "$API/zones/$cfzone_id/dns_records/$cfrecord_id" \
      type="$type" \
      name="$FQDN" \
      content="$contents" \
      ttl:=1 \
      proxied:=false \
      comment="ddns"
  fi
}

main 
