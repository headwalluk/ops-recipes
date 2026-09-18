#!/bin/bash
# Step 4: one line per IP that made "browser" page requests: pages, follow-up requests (assets + XHR), ASN.
# Usage: [OWN_IPS="203.0.113.7 198.51.100.9"] [API_AGENTS="..."] ./04-browser-visitors.sh week.log > visitors.tsv
# Output columns: IP  pages  follow_ups  ASN  organisation
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ACCESS_LOG=$1
VISITOR_COUNTS_FILE=$(mktemp)
trap 'rm -f "${VISITOR_COUNTS_FILE}"' EXIT

gawk -F'"' -v OWN_IPS="${OWN_IPS:-}" -v API_AGENTS="${API_AGENTS:-}" -f "${SCRIPT_DIR}/request-kind.awk" -f "${SCRIPT_DIR}/agent-claim.awk" -e '
    BEGIN { split(OWN_IPS, OWN_LIST, " "); for (OWN_INDEX in OWN_LIST) IS_OWN[OWN_LIST[OWN_INDEX]] = 1 }
    {
        split($1, HEAD_FIELDS, " ")
        CLIENT_IP = HEAD_FIELDS[1]
        if (CLIENT_IP in IS_OWN) next
        KIND = request_kind()
        if (KIND == "page" && agent_claim() == "browser") PAGES[CLIENT_IP]++
        # Assets and XHR only follow a page when a real browser ran it.
        if (KIND == "asset" || KIND == "xhr") FOLLOW_UPS[CLIENT_IP]++
    }
    END { for (CLIENT_IP in PAGES) print CLIENT_IP "\t" PAGES[CLIENT_IP] "\t" FOLLOW_UPS[CLIENT_IP] + 0 }
' "${ACCESS_LOG}" | sort > "${VISITOR_COUNTS_FILE}"

cut -f1 "${VISITOR_COUNTS_FILE}" | "${SCRIPT_DIR}/asn-lookup.sh" | cut -f2- | paste "${VISITOR_COUNTS_FILE}" -
