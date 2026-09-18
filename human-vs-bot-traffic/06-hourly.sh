#!/bin/bash
# Step 6: average page requests per hour of day (over the days in the file) for human, search engines, other bots.
# Usage: 06-hourly.sh classified.txt > hourly.tsv     (input is 05's output: "date hour class")
CLASSIFIED_FILE=$1

gawk '
    {
        DAYS[$1] = 1
        GROUP = ($3 == "human") ? "human" : ($3 == "search-engine") ? "search" : "bots"   # bots = declared, disguised, fake search engines and unknown
        COUNT[$2 " " GROUP]++
    }
    END {
        for (DAY_NAME in DAYS) DAY_COUNT++
        print "hour\thuman\tsearch_engines\tbots_and_unknown"
        for (HOUR = 0; HOUR < 24; HOUR++) {
            HOUR_KEY = sprintf("%02d", HOUR)
            printf "%s\t%.1f\t%.1f\t%.1f\n", HOUR_KEY, COUNT[HOUR_KEY " human"] / DAY_COUNT, COUNT[HOUR_KEY " search"] / DAY_COUNT, COUNT[HOUR_KEY " bots"] / DAY_COUNT
        }
    }' "${CLASSIFIED_FILE}"
