# ops-recipes

Small, practical tools that accompany the technical operations write-ups at
**[headwall-hosting.com/wordpress-woocommerce-ops/](https://headwall-hosting.com/wordpress-woocommerce-ops/)**.

Each directory is one recipe: the scripts behind a single article, plus a README
explaining how to run them and what the output means. They are written for
people running WordPress and WooCommerce on their own Linux servers, and they
lean on standard tools (`bash`, `gawk`, `grep`, `sort`, `uniq`) rather than
anything that needs installing into a site.

```bash
git clone https://github.com/headwalluk/ops-recipes.git
cd ops-recipes/<recipe>
```

## Recipes

| Recipe | What it does |
|---|---|
| [`human-vs-bot-traffic/`](human-vs-bot-traffic/) | Classify a week of Apache access-log page requests as human, verified search engine, declared crawler, disguised bot, fake Googlebot or unknown, using the User-Agent, the IP's network (GeoLite2-ASN) and whether anything ran the page. Includes an hour-of-day chart. |

## Ground rules

- **Read-only.** Nothing here changes a server. Copy the logs somewhere and work
  on the copy.
- **Logs contain personal data.** Visitor IP addresses are personal data in most
  jurisdictions. Keep the working copies private and delete them when you're done.
- **Tune before trusting.** Every recipe has a short list of patterns that were
  built for the sites in its article. Its README says which ones to review for
  your own sites.

## Licence

MIT. See [LICENSE](LICENSE).
