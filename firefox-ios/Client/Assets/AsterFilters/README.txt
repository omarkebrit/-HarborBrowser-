Aster ad-blocking resources

The committed ads.json is a small, working, independently authored startup pack for local development. Its metadata identifies it as a curated starter; it is not the full AdGuard filter pack. Native standard/strict Enhanced Tracking Protection remains active as a separate layer.

Production GitHub Actions runs Scripts/aster/prepare_ad_filters.py to replace the starter with official AdGuard Base and Mobile Ads optimized iOS lists, converted by checksum/commit-pinned SafariConverterLib 4.3.0. Scripts/aster/validate_ad_filters.swift requires over 1,000 rules and upstream exceptions and compiles them with real WebKit before building the app. Generation or validation failure fails the production build.

Generation packages source lists, licenses, notice, transformation report, source hashes and the actual rule count. Lists update when the app is built. There is no background in-app list updater and no added blanket third-party cookie rule or automatic video-site exemption. Standard/strict ETP, ad blocking and a deliberate per-host protection exception use the native browser settings and website-data stores.

WebKit filters cannot implement every advanced ad-blocking rule or guarantee ad-free video. This is an independent browser with WebKit ad filtering, not a Brave Shields implementation. Native tracker statistics describe the native ETP lists; ad-rule matches are not added to those counters.
