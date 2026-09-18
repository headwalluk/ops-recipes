# human-vs-bot-traffic

How much of a WordPress/WooCommerce site's page traffic is human? This recipe
classifies every **page request** in an Apache access log into one of six
classes, using three signals together:

1. **What the User-Agent claims.** Anyone can type any string here.
2. **Which network the IP belongs to (its ASN)**, from MaxMind's free
   GeoLite2-ASN database. Looked up locally; no IP leaves your machine.
3. **Whether anything ran the page**: did the same IP ever load an asset or
   fire an AJAX call? Browsers do; most HTML scrapers don't.

| Class | Rule |
|---|---|
| `search-engine` | Googlebot/bingbot User-Agent **and** AS15169 (Google) / AS8075 (Microsoft) |
| `fake-search-engine` | Googlebot/bingbot User-Agent from any other network |
| `declared-crawler` | Honest bot User-Agent: social previews, SEO tools, AI crawlers, scripts |
| `disguised-bot` | Browser User-Agent from a data-centre network |
| `human` | Browser User-Agent, consumer network, and the IP ran the page |
| `unknown` | Browser User-Agent, consumer network, page only (or no User-Agent at all) |

Written for the article
**[How much of your WooCommerce traffic is from actual humans?](https://headwall-hosting.com/wordpress-woocommerce-ops/human-vs-bot-traffic/)**,
which walks through each step with real numbers from three shops.

## Requirements

- `bash`, and **`gawk`** (the scripts use `gawk -f … -e …`; minimal Debian/Ubuntu
  installs ship `mawk`): `apt install gawk`
- `mmdblookup`: `apt install mmdb-bin`
- **GeoLite2-ASN**: free MaxMind account and licence key, then
  `apt install geoipupdate`, put the key in `/etc/GeoIP.conf` with
  `EditionIDs GeoLite2-ASN GeoLite2-Country`, and run `geoipupdate`.
  Default path `/var/lib/GeoIP/GeoLite2-ASN.mmdb`; override with `ASN_DATABASE=`.
- `gnuplot` (step 7 only)
- Logs in Apache **combined** format, one site per file.

## Quick start

```bash
# Work on a COPY. Five weekdays, trimmed by timestamp (rotation boundaries overlap).
ssh myserver 'cat /var/www/example.com/log/access.log.{12..6}' \
  | grep -E '\[(0[7-9]|1[01])/Sep/2026:' > week.log

export OWN_IPS="203.0.113.7"          # your office/home/monitoring IPs, space-separated
export API_AGENTS="Omnisend|Linnworks" # optional: integrations that poll your store

./01-request-kinds.sh week.log               # what kind of requests is this log made of?
./02-page-agents.sh week.log                 # what do the page requests claim to be?
./03-verify-search-engines.sh week.log       # are the Googlebots real?
./04-browser-visitors.sh week.log > visitors.tsv   # the "browsers": per IP, per network
./05-classify-pages.sh week.log > classified.txt   # the six classes
./06-hourly.sh classified.txt > hourly.tsv
gnuplot -e "SITE_A='hourly.tsv'; TITLE_A='My shop'" 07-plot.gp   # -> human-vs-bots.png

# The headline numbers:
gawk '{ COUNT[$3]++; TOTAL++ } END { for (CLASS in COUNT) printf "%5.1f%%  %s\n", 100 * COUNT[CLASS] / TOTAL, CLASS }' classified.txt | sort -rn
```

## The files

| File | Does |
|---|---|
| `request-kind.awk` | Shared function: each line is `api`, `asset`, `xhr`, `admin`, `meta`, `page` or `other` |
| `agent-claim.awk` | Shared function: the User-Agent claims `search-engine`, `declared-bot`, `browser` or `no-agent` |
| `asn-lookup.sh` | IPs on stdin → `IP  ASN  organisation`, cached in `asn-cache.tsv` in the current directory |
| `01-request-kinds.sh` | The request-kind mix of a log |
| `02-page-agents.sh` | Page requests by claimed agent; top declared bots |
| `03-verify-search-engines.sh` | Googlebot/bingbot claims counted by the network they really came from |
| `04-browser-visitors.sh` | Per-IP table for "browser" page requests: pages, follow-ups, ASN |
| `05-classify-pages.sh` | One line per page request: `date hour class protocol` |
| `06-hourly.sh` | Average-weekday requests per hour: humans, search engines, bots & unknown |
| `07-plot.gp` | gnuplot chart, one panel per site (up to three) |
| `hosting-networks.txt` | Organisation-name patterns treated as data-centre networks |

## Tune before you trust the numbers

- **Your own IPs.** Uptime monitors and your own browsing can be thousands of
  page requests a week. Find them with
  `gawk -F'"' '$6 ~ /HTTPie|curl|UptimeRobot|Pingdom/ { split($1, H, " "); print H[1], $6 }' week.log | sort | uniq -c | sort -rn | head`
  and put them in `OWN_IPS`.
- **`hosting-networks.txt`** was built by reading the top 60 networks across the
  three sites in the article. Run step 4, then read the top of the network
  survey for your own sites:

  ```bash
  gawk -F'\t' '{ KEY = $4 " " $5; IPS[KEY]++; PAGES[KEY] += $2; if ($3 > 0) RAN[KEY]++ }
      END { for (KEY in PAGES) printf "%6d pages %5d IPs %5.1f%% ran it  %s\n", PAGES[KEY], IPS[KEY], 100 * RAN[KEY] / IPS[KEY], KEY }' \
      visitors.tsv | sort -rn | head -60
  ```

  Consumer broadband shows most of its IPs running the page; clouds mostly don't.
  Add any data-centre network you find. Anything not listed defaults to
  "consumer". **Never list Apple, Cloudflare, Fastly or Akamai Technologies**:
  they carry iCloud Private Relay / WARP traffic, which is real people (step 5
  exempts them explicitly, because the generic `cloud` pattern would match
  Cloudflare). Avoid short patterns such as `colo`, which matches Colombian ISPs.
- **`agent-claim.awk`**: extend the declared-bot pattern if a crawler you care
  about slips through as `browser` (step 2's top list shows what matched).
- **`request-kind.awk`**: the asset and AJAX patterns assume WordPress and
  WooCommerce. If your theme fires no AJAX and serves assets from a CDN, humans
  may make no follow-up requests to the origin at all, and this recipe will
  count them as `unknown`.

## Caveats

- **This is a classification, not ground truth.** A headless browser on a
  residential proxy that runs JavaScript is counted as `human`; a real person
  with JavaScript off lands in `unknown`.
- **One IP is not one person.** Mobile carriers put many people behind one
  address, and a heavy "human" IP is often the shop's own staff.
- **Match Google by ASN number, never by name.** AS396982 is also "Google LLC":
  it is Google Cloud, where anyone can rent a server. For a single IP,
  reverse-then-forward DNS is stronger (`host 66.249.66.1` →
  `crawl-66-249-66-1.googlebot.com` → back to `66.249.66.1`).
- **HTTP/1.1 is a tell, not a verdict.** Page loads over HTTP/1.1 are mostly
  bots, but real Googlebot mostly uses HTTP/1.1 too. Never block on protocol
  alone.
- **The ASN cache does not expire.** `asn-cache.tsv` keeps each IP's first
  lookup. Delete it after a `geoipupdate`.

## Privacy

Access logs, `visitors.tsv`, `classified.txt` and `asn-cache.tsv` all contain
visitor IP addresses, which are personal data in most jurisdictions. Keep them
private, don't commit them, and delete them when you're done. `hourly.tsv` and
the chart are aggregates and safe to share.
