#!/bin/bash
# Step 2: split page requests by what the User-Agent claims, and list the top declared bots.
# Usage: [API_AGENTS="..."] ./02-page-agents.sh week.log
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ACCESS_LOG=$1

echo "Page requests by claimed agent:"
gawk -F'"' -v API_AGENTS="${API_AGENTS:-}" -f "${SCRIPT_DIR}/request-kind.awk" -f "${SCRIPT_DIR}/agent-claim.awk" -e '
    request_kind() == "page" { CLAIM_COUNT[agent_claim()]++; PAGE_COUNT++ }
    END {
        for (CLAIM_NAME in CLAIM_COUNT) {
            printf "%8d  %5.1f%%  %s\n", CLAIM_COUNT[CLAIM_NAME], 100 * CLAIM_COUNT[CLAIM_NAME] / PAGE_COUNT, CLAIM_NAME
        }
    }' "${ACCESS_LOG}" | sort -rn

echo
echo "Top declared bots (first bot-like token in the User-Agent):"
gawk -F'"' -v API_AGENTS="${API_AGENTS:-}" -f "${SCRIPT_DIR}/request-kind.awk" -f "${SCRIPT_DIR}/agent-claim.awk" -e '
    request_kind() == "page" && agent_claim() ~ /declared-bot|search-engine/ {
        if (match($6, /[A-Za-z][A-Za-z0-9._-]*([Bb]ot|[Cc]rawler|[Ss]pider|externalhit|agent)[A-Za-z0-9._-]*/)) {
            print substr($6, RSTART, RLENGTH)
        } else {
            print substr($6, 1, 30)
        }
    }' "${ACCESS_LOG}" | sort | uniq -c | sort -rn | head -15
