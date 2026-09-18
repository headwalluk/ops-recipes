# Step 7: one chart panel per site from 06's hourly averages. One to three sites.
# Usage:
#   gnuplot -e "SITE_A='a.tsv'; TITLE_A='My shop'" 07-plot.gp
#   gnuplot -e "SITE_A='a.tsv'; SITE_B='b.tsv'; SITE_C='c.tsv'; TITLE_A='...'; TITLE_B='...'; TITLE_C='...'" 07-plot.gp
# Writes human-vs-bots.png (override with OUTPUT_FILE='name.png').
if (!exists("SITE_A")) { print "07-plot: set at least SITE_A='hourly.tsv'"; exit status 1 }
if (!exists("TITLE_A")) TITLE_A = "Site A"
if (!exists("TITLE_B")) TITLE_B = "Site B"
if (!exists("TITLE_C")) TITLE_C = "Site C"
if (!exists("OUTPUT_FILE")) OUTPUT_FILE = "human-vs-bots.png"
PANEL_COUNT = 1 + exists("SITE_B") + exists("SITE_C")

set terminal pngcairo size (500 * PANEL_COUNT), 520 font "Sans,11" noenhanced
set output OUTPUT_FILE
set datafile separator "\t"
set key autotitle columnhead outside bottom center horizontal
set multiplot layout 1, PANEL_COUNT title "Page requests per hour of day, average weekday"
set xrange [-0.5:23.5]
set xtics 0,3,21
set grid ytics lc rgb "#dddddd"
set xlabel "hour"
set yrange [0:*]
set style line 1 lc rgb "#1b7837" lw 3
set style line 2 lc rgb "#2166ac" lw 2
set style line 3 lc rgb "#b2182b" lw 2

set ylabel "requests / hour"
set title TITLE_A
plot SITE_A using 1:4 with lines ls 3 title "bots & unknown", '' using 1:3 with lines ls 2 title "search engines", '' using 1:2 with lines ls 1 title "humans"
unset ylabel
if (exists("SITE_B")) {
    set title TITLE_B
    plot SITE_B using 1:4 with lines ls 3 title "bots & unknown", '' using 1:3 with lines ls 2 title "search engines", '' using 1:2 with lines ls 1 title "humans"
}
if (exists("SITE_C")) {
    set title TITLE_C
    plot SITE_C using 1:4 with lines ls 3 title "bots & unknown", '' using 1:3 with lines ls 2 title "search engines", '' using 1:2 with lines ls 1 title "humans"
}
unset multiplot
