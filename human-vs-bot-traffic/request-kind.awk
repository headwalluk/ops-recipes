# Shared by every step: sort one combined-format log line into a request kind.
# Use with: gawk -F'"' -v API_AGENTS="Omnisend|Linnworks" -f request-kind.awk -e '...'
# Fields: $2 request line, $4 referer, $6 User-Agent.
#
# API_AGENTS (optional): regex of User-Agents belonging to integrations that
# poll your store, e.g. "Omnisend|Linnworks". WooCommerce REST (/wp-json/wc/v3)
# counts as API whether or not it is set.

# Return api, asset, xhr, admin, meta, page or other for the current line.
function request_kind(    request_parts, method, path_and_query, path, kind) {
    split($2, request_parts, " ")
    method = request_parts[1]
    path_and_query = request_parts[2]
    path = path_and_query
    sub(/\?.*/, "", path)
    kind = "other"
    if ((API_AGENTS != "" && $6 ~ API_AGENTS) || path ~ /^\/wp-json\/wc\/v[0-9]/) {
        kind = "api"
    } else if (path ~ /^\/wp-(content|includes)\// || path ~ /\.(css|js|mjs|map|png|jpe?g|gif|webp|avif|svg|ico|woff2?|ttf|otf|eot|mp4|webm|pdf)$/) {
        kind = "asset"
    } else if (path_and_query ~ /wc-ajax=/ || path ~ /^\/wp-json\// || path == "/wp-admin/admin-ajax.php") {
        kind = "xhr"
    } else if (path ~ /^\/wp-(admin|login\.php|cron\.php)/ || path == "/xmlrpc.php") {
        kind = "admin"
    } else if (path == "/robots.txt" || path ~ /\.(xml|txt)$/ || path ~ /\/feed\/?$/) {
        kind = "meta"
    } else if (method == "GET" || method == "HEAD") {
        kind = "page"
    }
    return kind
}
