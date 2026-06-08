# Deploying the cache-server Worker

This Worker proxies and caches football-data.org responses so every device
shares one cache instead of one shared API key hitting the rate limit. Files:
`worker.ts` (the proxy logic), `wrangler.toml` (config).

You don't need a global `wrangler` install — every command below uses `npx wrangler`,
which downloads and runs it on demand.

## 1. Log in to Cloudflare

```sh
cd cloudflare-worker
npx wrangler login
```

This opens a browser window to authorize the CLI against your Cloudflare account.
No custom domain needed — we'll use the free `*.workers.dev` subdomain.

## 2. Set the secrets

The Worker needs your football-data.org API key (it injects `X-Auth-Token`
server-side so the key never ships in the app):

```sh
npx wrangler secret put FOOTBALL_DATA_API_KEY
```

Paste the key when prompted (the same value as `FOOTBALL_DATA_API_KEY` in
`Lappeleken/App/Secrets.xcconfig`).

Optionally lock the proxy down so only your app can use it — generate a random
string and set it as a second secret:

```sh
openssl rand -hex 32
npx wrangler secret put CLIENT_SHARED_SECRET
```

If you skip this, the Worker is open to anyone who finds its URL (they'd be
spending *your* football-data.org quota). Recommended for a launch.
Keep the value handy — you'll add it to the iOS app's xcconfig later.

## 3. Deploy

```sh
npx wrangler deploy
```

On first deploy, Wrangler provisions a `*.workers.dev` subdomain for your
account if you don't have one yet (it'll prompt you to pick a subdomain name).
The output ends with a line like:

```
Published lucky-football-slip-cache (x.xx sec)
  https://lucky-football-slip-cache.<your-subdomain>.workers.dev
```

That URL is what you'll set as `AppConfig.CacheServer.baseURL`.

## 4. Verify it's live

```sh
curl -i "https://lucky-football-slip-cache.<your-subdomain>.workers.dev/api/football/competitions"
```

- If you set `CLIENT_SHARED_SECRET`, add `-H "X-Client-Secret: <your-secret>"`
  or you'll get `401 Unauthorized`.
- You should get a `200` with JSON from football-data.org.

## 5. Confirm caching: MISS then HIT

Run the **same** request twice in a row:

```sh
curl -sI "https://lucky-football-slip-cache.<your-subdomain>.workers.dev/api/football/competitions" | grep -i x-cache
curl -sI "https://lucky-football-slip-cache.<your-subdomain>.workers.dev/api/football/competitions" | grep -i x-cache
```

Expected:
- 1st request: `X-Cache: MISS` (fetched from football-data.org, stored at the edge)
- 2nd request: `X-Cache: HIT` (served from Cloudflare's cache, no upstream call)

You may also see `X-Cache: STALE` later on — that means the cached entry passed
its TTL but is still within the stale-while-revalidate window; the Worker serves
it immediately and refreshes it in the background.

## 6. Try the live-match TTL hint

```sh
curl -sI "https://.../api/football/matches/12345?live=1" | grep -i x-cache
```

`?live=1` makes the Worker use a 15-second TTL instead of 5 minutes — this is
what the iOS monitor will send while a match is in progress (see CLAUDE.md
"IN PROGRESS" for the matching iOS-side change).

## Updating the Worker later

Edit `worker.ts`, then redeploy:

```sh
npx wrangler deploy
```

## Cache tiers (for reference)

| Endpoint pattern              | TTL    |
|-------------------------------|--------|
| `matches/{id}?live=1`         | 15s    |
| `matches/{id}` (not live)     | 5 min  |
| `matches` (lists/fixtures)    | 10 min |
| `competitions`, `teams/{id}`  | 24 h   |

Stale-while-revalidate is on for all tiers (serves a stale copy instantly while
refreshing in the background, up to 2x the TTL old).
