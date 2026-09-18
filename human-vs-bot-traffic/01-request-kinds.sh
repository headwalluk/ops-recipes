#!/bin/bash
# Step 1: how many requests of each kind (page, asset, xhr, api, admin, meta, other) a log holds.
# Usage: [API_AGENTS="Omnisend|Linnworks"] ./01-request-kinds.sh week.log
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
ACCESS_LOG=$1

gawk -F'"' -v API_AGENTS="${API_AGENTS:-}" -f "${SCRIPT_DIR}/request-kind.awk" -e '
    { KIND_COUNT[request_kind()]++; TOTAL_COUNT++ }
    END {
        for (KIND_NAME in KIND_COUNT) {
            printf "%8d  %5.1f%%  %s\n", KIND_COUNT[KIND_NAME], 100 * KIND_COUNT[KIND_NAME] / TOTAL_COUNT, KIND_NAME
        }
        printf "%8d  total\n", TOTAL_COUNT
    }' "${ACCESS_LOG}" | sort -rn
