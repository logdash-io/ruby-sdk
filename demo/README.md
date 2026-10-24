# LogDash Ruby SDK Demo

Checks that the published gem installs from RubyGems and that what it sends arrives.
CI runs it after each release, and the `Check deployed package` workflow runs it by hand on any branch.

```
LOGDASH_API_KEY=<ingest key> LOGDASH_PERSONAL_API_KEY=<personal key> ./demo/run.sh
```

It sends with the ingest key and reads the logs and metric back with the personal key, an `ldp_` key with logs:read and metrics:read restricted to the same project.
`LOGDASH_VERSION=<version>` checks that version instead of the latest, and waits until RubyGems serves it.
It needs Docker, curl and jq.
