#!/bin/bash
# Read IPs on stdin, print "IP<TAB>ASN<TAB>organisation" from the local GeoLite2-ASN database.
# Results are cached in ASN_CACHE_FILE so repeat runs only look up new addresses.
ASN_DATABASE=${ASN_DATABASE:-/var/lib/GeoIP/GeoLite2-ASN.mmdb}
ASN_CACHE_FILE=${ASN_CACHE_FILE:-asn-cache.tsv}

# Without these every IP would silently become "unknown" and be cached that way.
if ! command -v mmdblookup > /dev/null; then
    echo "asn-lookup: mmdblookup not found (Debian/Ubuntu: apt install mmdb-bin)" >&2
    exit 1
fi
if [ ! -r "${ASN_DATABASE}" ]; then
    echo "asn-lookup: cannot read ${ASN_DATABASE} (set ASN_DATABASE, or install GeoLite2-ASN via geoipupdate)" >&2
    exit 1
fi
touch "${ASN_CACHE_FILE}"

declare -A CACHED_LINE
while IFS=$'\t' read -r CACHED_IP CACHED_REST; do
    CACHED_LINE[${CACHED_IP}]=${CACHED_REST}
done < "${ASN_CACHE_FILE}"

while read -r IP_ADDRESS; do
    if [ -z "${CACHED_LINE[${IP_ADDRESS}]+set}" ]; then
        # mmdblookup prints a small JSON-ish map; pull the number and the quoted name out of it.
        # Its stderr is dropped because an address absent from the database is expected (-> "unknown").
        LOOKUP_RESULT=$(mmdblookup --file "${ASN_DATABASE}" --ip "${IP_ADDRESS}" 2>/dev/null \
            | awk '/<uint32>/ { AS_NUMBER = $1 } /<utf8_string>/ { match($0, /"[^"]*"/); AS_NAME = substr($0, RSTART + 1, RLENGTH - 2) }
                   END { printf "AS%s\t%s", (AS_NUMBER == "" ? "?" : AS_NUMBER), (AS_NAME == "" ? "unknown" : AS_NAME) }')
        CACHED_LINE[${IP_ADDRESS}]=${LOOKUP_RESULT}
        printf '%s\t%s\n' "${IP_ADDRESS}" "${LOOKUP_RESULT}" >> "${ASN_CACHE_FILE}"
    fi
    printf '%s\t%s\n' "${IP_ADDRESS}" "${CACHED_LINE[${IP_ADDRESS}]}"
done
