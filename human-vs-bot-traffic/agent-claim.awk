# Shared: what the User-Agent ($6) claims to be. Nothing here is verified.

# Return search-engine, declared-bot, no-agent or browser.
function agent_claim(    agent, claim) {
    agent = $6
    claim = "browser"
    if (agent == "" || agent == "-") {
        claim = "no-agent"
    } else if (agent ~ /Googlebot|bingbot/) {
        claim = "search-engine"
    } else if (agent ~ /[Bb]ot\b|[Cc]rawl|[Ss]pider|[Ss]lurp|externalhit|meta-external|Discovery|HeadlessChrome|python|curl|[Ww]get|Go-http|[Jj]ava\/|okhttp|axios|node-fetch|[Ss]crapy|httpx|libwww|HTTPie|WordPress\//) {
        claim = "declared-bot"
    }
    return claim
}
