#!/bin/bash
# Step 5: label every page request human / search-engine / fake-search-engine /
# declared-crawler / disguised-bot / unknown, and print "date hour class protocol" per request.
# Usage: [OWN_IPS="203.0.113.7"] [API_AGENTS="..."] ./05-classify-pages.sh week.log > classified.txt
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ACCESS_LOG=$1
HOSTING_PATTERNS=$(grep -v '^#' "${SCRIPT_DIR}/hosting-networks.txt" | grep -v '^$' | paste -sd'|')
IP_FOLLOWED_FILE=$(mktemp)
IP_INFO_FILE=$(mktemp)
trap 'rm -f "${IP_FOLLOWED_FILE}" "${IP_INFO_FILE}"' EXIT

# Pass 1: per IP, did it ever load an asset or XHR? Plus its ASN.
gawk -F'"' -v API_AGENTS="${API_AGENTS:-}" -f "${SCRIPT_DIR}/request-kind.awk" -e '
    {
        split($1, HEAD_FIELDS, " ")
        KIND = request_kind()
        if (KIND == "page") SEEN[HEAD_FIELDS[1]] = 1
        if (KIND == "asset" || KIND == "xhr") FOLLOWED[HEAD_FIELDS[1]] = 1
    }
    END { for (CLIENT_IP in SEEN) print CLIENT_IP "\t" (CLIENT_IP in FOLLOWED ? 1 : 0) }
' "${ACCESS_LOG}" | sort > "${IP_FOLLOWED_FILE}"
cut -f1 "${IP_FOLLOWED_FILE}" | "${SCRIPT_DIR}/asn-lookup.sh" | cut -f2- | paste "${IP_FOLLOWED_FILE}" - > "${IP_INFO_FILE}"

# Pass 2: NR==FNR loads ip-info (IP, followed, ASN, org), then each page request is labelled.
# FS='"' between the file names switches the separator as gawk opens the log.
gawk -F'\t' -v OWN_IPS="${OWN_IPS:-}" -v API_AGENTS="${API_AGENTS:-}" -v HOSTING_PATTERNS="${HOSTING_PATTERNS}" \
    -f "${SCRIPT_DIR}/request-kind.awk" -f "${SCRIPT_DIR}/agent-claim.awk" -e '
    BEGIN { split(OWN_IPS, OWN_LIST, " "); for (OWN_INDEX in OWN_LIST) IS_OWN[OWN_LIST[OWN_INDEX]] = 1 }
    NR == FNR {
        FOLLOWED[$1] = $2
        ASN_OF[$1] = $3
        ORG_OF[$1] = $4
        next
    }
    {
        split($1, HEAD_FIELDS, " ")
        CLIENT_IP = HEAD_FIELDS[1]
        if (CLIENT_IP in IS_OWN || request_kind() != "page") next
        CLAIM = agent_claim()
        ORG_NAME = tolower(ORG_OF[CLIENT_IP])
        # Privacy relays (iCloud Private Relay, WARP) carry real people: never hosting.
        IS_RELAY = (ORG_NAME ~ /^(apple|cloudflare|fastly|akamai technologies)/)
        IS_HOSTING = !IS_RELAY && (ORG_NAME ~ tolower(HOSTING_PATTERNS))
        if (CLAIM == "search-engine") {
            CLASS = (($6 ~ /bingbot/ && ASN_OF[CLIENT_IP] == "AS8075") || ($6 ~ /Googlebot/ && ASN_OF[CLIENT_IP] == "AS15169")) ? "search-engine" : "fake-search-engine"
        } else if (CLAIM == "declared-bot") {
            CLASS = "declared-crawler"
        } else if (CLAIM == "no-agent") {
            CLASS = "unknown"
        } else if (IS_HOSTING) {
            CLASS = "disguised-bot"
        } else if (FOLLOWED[CLIENT_IP] == 1) {
            CLASS = "human"
        } else {
            CLASS = "unknown"
        }
        split($2, REQUEST_PARTS, " ")
        # [07/Sep/2026:13:45:01 -> "07/Sep/2026 13"
        print substr(HEAD_FIELDS[4], 2, 11), substr(HEAD_FIELDS[4], 14, 2), CLASS, (REQUEST_PARTS[3] == "" ? "none" : REQUEST_PARTS[3])
    }
' "${IP_INFO_FILE}" FS='"' "${ACCESS_LOG}"
