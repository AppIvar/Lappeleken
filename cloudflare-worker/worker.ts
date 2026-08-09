/**
 * Cloudflare Worker: caching proxy for football-data.org.
 *
 * iOS calls:   GET https://<worker>.workers.dev/api/football/<endpoint>
 * Worker calls: GET https://api.football-data.org/v4/<endpoint>
 *
 * Why this exists: every device shares the same football-data.org API key, so
 * direct calls hit the rate limit cliff. This Worker injects the key
 * server-side (it never ships in the app) and caches responses at Cloudflare's
 * edge so all devices share one cache.
 *
 * Cache tiers (see CLAUDE.md "IN PROGRESS — Cloudflare proxy"):
 *   live match (matches/{id}?live=1) -> 15s
 *   non-live match (matches/{id})    -> 5m
 *   fixtures/lists (matches)         -> 10m
 *   competitions, squads (teams/*)   -> 24h
 *
 * Responses carry X-Cache: HIT | STALE | MISS so the client (and you, during
 * setup) can confirm caching is working.
 */

export interface Env {
  FOOTBALL_DATA_API_KEY: string;
  CLIENT_SHARED_SECRET?: string;
}

const FOOTBALL_DATA_BASE = "https://api.football-data.org/v4";
const PROXY_PREFIX = "/api/football/";

const TTL = {
  liveMatch: 15,
  match: 300,
  fixtures: 600,
  longLived: 86400,
} as const;

function ttlFor(pathSegments: string[], isLive: boolean): number {
  if (pathSegments[0] === "matches") {
    if (pathSegments.length > 1) {
      return isLive ? TTL.liveMatch : TTL.match;
    }
    return TTL.fixtures;
  }
  if (pathSegments[0] === "competitions" || pathSegments[0] === "teams") {
    return TTL.longLived;
  }
  return TTL.match;
}

/** Web origins allowed to use this proxy from a browser (a browser can't send the secret). */
const ALLOWED_ORIGINS = [
  "http://localhost:5173", // Vite dev server
  "http://localhost:4173", // Vite preview
  // Add the deployed web app's origin here when it goes live, e.g.
  // "https://luckyfootballslip.app"
];

/** CORS headers for a request; echoes the Origin only if it's allowlisted. */
function corsHeadersFor(origin: string | null): Record<string, string> {
  const headers: Record<string, string> = {
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-Client-Secret, X-Client-ID",
    "Access-Control-Max-Age": "86400",
  };
  if (origin && ALLOWED_ORIGINS.includes(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
    headers["Vary"] = "Origin";
  }
  return headers;
}

/** Copies CORS headers onto a response (mutates its headers). */
function applyCors(response: Response, corsHeaders: Record<string, string>): void {
  for (const [key, value] of Object.entries(corsHeaders)) {
    response.headers.set(key, value);
  }
}

function fetchFromOrigin(upstreamURL: string, env: Env): Promise<Response> {
  return fetch(upstreamURL, {
    headers: {
      "X-Auth-Token": env.FOOTBALL_DATA_API_KEY,
      "Accept": "application/json",
    },
  });
}

/**
 * Fetches the origin, stores the result for `ttl` seconds, and (when
 * `returnResponse` is true) hands back a client-facing copy tagged X-Cache: MISS.
 * Errors are never cached, so a bad upstream response self-heals on the next request.
 */
async function refreshAndStore(
  upstreamURL: string,
  cacheKey: Request,
  ttl: number,
  env: Env,
  cache: Cache,
  returnResponse: boolean
): Promise<Response | undefined> {
  const upstreamResponse = await fetchFromOrigin(upstreamURL, env);
  const contentType = upstreamResponse.headers.get("Content-Type") ?? "application/json";

  if (!upstreamResponse.ok) {
    if (!returnResponse) return undefined;
    return new Response(await upstreamResponse.text(), {
      status: upstreamResponse.status,
      headers: { "Content-Type": contentType },
    });
  }

  const body = await upstreamResponse.text();
  const stored = new Response(body, {
    status: upstreamResponse.status,
    headers: {
      "Content-Type": contentType,
      "Cache-Control": `public, max-age=${ttl}`,
      "X-Cached-At": String(Date.now()),
    },
  });

  await cache.put(cacheKey, stored.clone());
  if (!returnResponse) return undefined;

  const out = new Response(stored.body, stored);
  out.headers.set("X-Cache", "MISS");
  return out;
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const origin = request.headers.get("Origin");
    const corsHeaders = corsHeadersFor(origin);

    // Preflight: browsers may send OPTIONS before the real GET.
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }
    if (request.method !== "GET") {
      return new Response("Method not allowed", { status: 405, headers: corsHeaders });
    }
    if (!url.pathname.startsWith(PROXY_PREFIX)) {
      return new Response("Not found", { status: 404, headers: corsHeaders });
    }

    // Auth: accept a valid shared secret (iOS) OR an allowlisted browser Origin (web).
    const hasValidSecret =
      !!env.CLIENT_SHARED_SECRET &&
      request.headers.get("X-Client-Secret") === env.CLIENT_SHARED_SECRET;
    const isAllowedOrigin = origin !== null && ALLOWED_ORIGINS.includes(origin);
    if (env.CLIENT_SHARED_SECRET && !hasValidSecret && !isAllowedOrigin) {
      return new Response("Unauthorized", { status: 401, headers: corsHeaders });
    }

    const pathSegments = url.pathname.slice(PROXY_PREFIX.length).split("/").filter(Boolean);
    const isLive = url.searchParams.get("live") === "1";
    const ttl = ttlFor(pathSegments, isLive);

    // `live=1` only steers our TTL choice — football-data.org doesn't know about it.
    const upstreamSearch = new URLSearchParams(url.search);
    upstreamSearch.delete("live");
    const upstreamQuery = upstreamSearch.toString();
    const upstreamURL = `${FOOTBALL_DATA_BASE}/${pathSegments.join("/")}${upstreamQuery ? `?${upstreamQuery}` : ""}`;

    const cache = caches.default;
    // Normalize the cache key by stripping `live` — it only steers TTL, not the
    // response — so live (?live=1) and non-live reads of the same match share one
    // cache entry instead of splitting into two.
    const cacheKeyURL = new URL(url.toString());
    cacheKeyURL.searchParams.delete("live");
    const cacheKey = new Request(cacheKeyURL.toString(), { method: "GET" });

    const cached = await cache.match(cacheKey);
    if (cached) {
      const cachedAt = Number(cached.headers.get("X-Cached-At") ?? "0");
      const ageSeconds = (Date.now() - cachedAt) / 1000;

      if (ageSeconds <= ttl) {
        const fresh = new Response(cached.body, cached);
        fresh.headers.set("X-Cache", "HIT");
        applyCors(fresh, corsHeaders);
        return fresh;
      }
      if (ageSeconds <= ttl * 2) {
        // Stale-while-revalidate: serve the stale copy now, refresh in the background.
        const stale = new Response(cached.body, cached);
        stale.headers.set("X-Cache", "STALE");
        applyCors(stale, corsHeaders);
        ctx.waitUntil(refreshAndStore(upstreamURL, cacheKey, ttl, env, cache, false));
        return stale;
      }
      // Older than 2x TTL — fall through and refetch synchronously.
    }

    const response =
      (await refreshAndStore(upstreamURL, cacheKey, ttl, env, cache, true)) ??
      new Response("Upstream error", { status: 502 });
    applyCors(response, corsHeaders);
    return response;
  },
};
