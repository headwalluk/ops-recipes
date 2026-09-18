#!/bin/bash
# Step 3: for page requests claiming Googlebot/bingbot, count them by the network (ASN) the IP really belongs to.
# Usage: [API_AGENTS="..."] ./03-verify-search-engines.sh week.log
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ACCESS_LOG=$1
CLAIMS_FILE=$(mktemp)
CLAIM_ASNS_FILE=$(mktemp)
trap 'rm -f "${CLAIMS_FILE}" "${CLAIM_ASNS_FILE}"' EXIT

# Distinct IPs making claimed search-engine page requests, with request counts.
gawk -F'"' -v API_AGENTS="${API_AGENTS:-}" -f "${SCRIPT_DIR}/request-kind.awk" -f "${SCRIPT_DIR}/agent-claim.awk" -e '
    request_kind() == "page" && agent_claim() == "search-engine" {
        split($1, HEAD_FIELDS, " ")
        ENGINE_NAME = ($6 ~ /bingbot/) ? "bingbot" : "Googlebot"
        print HEAD_FIELDS[1] "\t" ENGINE_NAME
    }' "${ACCESS_LOG}" | sort | uniq -c > "${CLAIMS_FILE}"

gawk '{ print $2 }' "${CLAIMS_FILE}" | sort -u | "${SCRIPT_DIR}/asn-lookup.sh" > "${CLAIM_ASNS_FILE}"

# Join counts to ASNs: NR==FNR reads the lookup first, then the claims.
gawk -F'\t' 'NR == FNR { ASN_OF[$1] = $2 " " $3; next }
    { split($0, COUNT_AND_IP, " "); REQUESTS[$2 " via " ASN_OF[COUNT_AND_IP[2]]] += COUNT_AND_IP[1] }
    END { for (KEY in REQUESTS) printf "%8d  %s\n", REQUESTS[KEY], KEY }' "${CLAIM_ASNS_FILE}" "${CLAIMS_FILE}" | sort -rn
