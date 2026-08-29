---
authors:
  - ginuerzh
categories:
  - Tutorial
  - Reverse Proxy
readtime: 20
date: 2026-08-28
comments: true
---

# Building a Website Mirror with GOST Reverse Proxy

In some network environments, access to certain websites is unstable. Setting up a "mirror site" is a common solution: move the target site as-is onto your own domain or server, so visitors get the same content transparently.

But "mirroring a website" is far more than just forwarding the homepage HTML. A modern site (take GitHub for example) spreads its resources across multiple domains (`github.com`, `raw.githubusercontent.com`, `avatars.githubusercontent.com`, `github.githubassets.com`, …), and the links, redirects, cookies, and security policies inside its pages are all hard-coded to the original domain. A naive forward would send the user back to the origin on every link click and load images from the origin domain — the mirror would be pointless.

This article uses GitHub as an example to walk through how to turn a multi-domain site into a real mirror using GOST's [reverse proxy](https://latest.gost.run/en/tutorials/reverse-proxy).

<!-- more -->

## Core Idea: Encode the "Return Route" into the URL

The one problem a mirror must solve is this: **when a user clicks a link inside the mirror, how does GOST know which upstream domain that link originally pointed to?**

The answer is to encode the upstream domain **into the mirror URL**:

```
Original URL:  https://github.com/go-gost/gost
Mirror URL:    http://127.0.0.1:8000/github.com/go-gost/gost
                        ↑                     ↑
                  mirror address     first path segment = upstream domain
```

Put `github.com` as the first path segment. The whole loop then becomes a pair of inverse transforms:

| Direction | Transform | Mechanism |
|-----------|-----------|-----------|
| Outbound: upstream URL → mirror URL | `https://github.com/...` → `http://mirror/github.com/...` | regex rewrite of response body / `Location` header |
| Return: mirror URL → upstream URL | `http://mirror/github.com/...` → request `/...` on `github.com` | `matcher.rule` picks the node + `rewriteURL` strips the prefix + `http.host` restores Host |

One regex in each direction is enough to make every link inside the mirror route back into the mirror instead of bouncing to the origin.

## One Node Serves One Upstream Domain

There is a constraint that must be stated first: a GOST node is **one address + one SNI**. When dialing `github.com:443` over TLS, the SNI and certificate verification are pinned to that address, and the Host is also given statically by config. This means **one node can only correctly serve one upstream domain** — you cannot cram `github.com` and `gist.github.com` into the same node, because connecting to `gist.github.com` requires an SNI of `gist.github.com`, otherwise certificate verification fails.

So "mirroring GitHub" is essentially **one node per upstream domain**, with `matcher.rule` sharding by the first path segment. Fortunately these domains are all statically known at config time, so no runtime dynamic resolution is needed.

> The one exception is `*.github.io` (GitHub Pages): it is routed by the **Host header** rather than SNI, and all subdomains share a single `*.github.io` wildcard certificate and resolve to the same anycast pool. So this kind of "Host-routed" infinite subdomain can be served with **one node + `http.hostPattern`** that restores the Host dynamically — see below.

> This also explains why a **plaintext host prefix** (`/github.com/...`) is used here instead of base64: GOST's response-body rewrite is pure regex substitution, and a regex cannot compute base64. For sites like GitHub the upstream domains only ever take the shape `[a-z0-9-]+\.(github|githubusercontent|githubassets)\.com`, so the first path segment is completely safe, and plaintext is easy to debug (curl-readable).

## Three Layers of Rewriting

Like [LLM Routing](llm-router.md), mirror rewriting has three layers, each mapping to one GOST capability.

### 1. Response Body Rewriting

The page HTML is full of links pointing at the origin. Use [response body rewriting](https://latest.gost.run/en/tutorials/reverse-proxy/#_12) to swap their host for the mirror address:

```yaml
rewriteResponseBody:
  - type: text/html,application/json
    match: 'https://(github\.com|raw\.githubusercontent\.com|...)'
    replacement: 'http://127.0.0.1:8000/$1'
    maxChunkSize: 8388608
```

`$1` captures the whole host; after substitution the origin host naturally becomes the first path segment of the mirror URL, matching the return-route convention exactly.

### 2. Response Header Rewriting

Response headers hide a class of "covert origin references" that are more subtle than body links:

* **`Location`** — 302/301 redirects. Many `github.com` requests bounce back to the origin; the redirect target must be encoded as a mirror URL too, otherwise one redirect leaves the mirror.
* **`Set-Cookie`'s `Domain`** — login-state cookies are bound to the origin domain. Under anonymous browsing, if `Domain` is not stripped, the cookie leaks across paths to other upstreams after the domain is removed.
* **`Content-Security-Policy` / `Strict-Transport-Security`** — CSP blocks loading mirror-domain resources, and HSTS forces HTTPS. The mirror runs over HTTP, so both must be deleted.

These are GOST's header rewriting capabilities (`rewriteResponseHeader`), working as "header-name regex + value regex replacement":

```yaml
rewriteResponseHeader:
  - name: '(?i)^location$'
    match: 'https://github\.com'
    replacement: 'http://127.0.0.1:8000/github.com'
  - name: '(?i)^set-cookie$'
    match: '(?i)domain=\.?github\.com;?\s*'
    replacement: ''          # value emptied → header deleted
  - name: '(?i)^content-security-policy(-report-only)?$'
    match: '.*'
    replacement: ''
  - name: '(?i)^strict-transport-security$'
    match: '.*'
    replacement: ''
```

### 3. Request Header Rewriting (Delete, Not Encode)

The request-header direction is the inverse of the response — when the browser hits the mirror, the `Referer`/`Origin` it sends **are already mirror addresses** (`http://127.0.0.1:8000/...`). They must not be "encoded forward" again, or the mirror address would leak to the upstream. The correct move is to **delete** them:

```yaml
rewriteRequestHeader:
  - name: '(?i)^(referer|origin|x-forwarded-host)$'
    match: '.*'
    replacement: ''
```

GitHub's CSRF protection relies on form tokens rather than `Referer`, so deletion is both simplest and safest.

### 4. Exception: Dynamic Host for `*.github.io`

Earlier I said "one node per upstream domain" because SNI is static. But `*.github.io` (GitHub Pages) is different: Fastly routes content by the **Host header**, not SNI. Verified empirically —

* all `*.github.io` resolve to the same anycast pool (`185.199.108~111.153`);
* they share one `*.github.io` wildcard certificate, so any subdomain as SNI passes verification;
* on the same IP, `Host: microsoft.github.io` returns Microsoft's page and `Host: google.github.io` returns Google's page — **content is decided by the Host header**.

So this kind of infinite subdomain doesn't need "one node per subdomain"; it needs a single node that extracts the Host from the path dynamically via `http.hostPattern`:

```yaml
- name: githubio
  matcher:
    rule: PathRegexp(`^/[a-z0-9-]+\.github\.io/`)
  addr: github.io:443
  tls: { secure: true, serverName: github.io }   # static SNI, wildcard cert covers it
  http:
    hostPattern: '^/([a-z0-9-]+\.github\.io)/'    # extract host from path
    host: '$1'                                    # Host = first capture group
    rewriteURL:
      - { match: '^/[a-z0-9-]+\.github\.io/', replacement: '/' }   # strip host prefix
    rewriteRequestHeader:
      - { name: '(?i)^cookie$', match: '.*', replacement: '' }
```

`hostPattern` is a regex matched against the URL path; on a match it treats `http.host` as a template and expands the `$1`/`$2` capture groups. It **only rewrites the Host header** — it does not change the dial target or SNI (both remain static) — so it fits Host-routed upstreams exactly, and that is its only capability difference from a normal node.

## Complete Configuration Example

Below is an anonymous read-only GitHub mirror on [GOST v3](https://latest.gost.run/en/). The client hits GOST over HTTP (`127.0.0.1:8000`), and GOST dials the upstream over HTTPS with certificate verification — **no MITM, no client-side certificate trust, end to end**.

```yaml
# gost.yaml
# The union of every mirrored domain, collapsed into a single source of truth
# via a YAML anchor. To add an upstream domain: add one entry here + one node.
mirrorOrigins: &origins 'https://(www\.github\.com|gist\.github\.com|api\.github\.com|codeload\.github\.com|github\.githubassets\.com|opengraph\.githubassets\.com|avatars\.githubusercontent\.com|raw\.githubusercontent\.com|camo\.githubusercontent\.com|user-images\.githubusercontent\.com|release-assets\.githubusercontent\.com|github\.com)'

services:
  - name: github-mirror
    addr: :8000
    handler:
      type: tcp
      metadata:
        sniffing: true
    listener:
      type: tcp
    forwarder:
      nodes:
        # Fallback: the bare homepage GET / and any path without an origin prefix
        - name: github-root
          matcher:
            rule: PathPrefix(`/`)
          addr: github.com:443
          tls: { secure: true, serverName: github.com }
          http:
            host: github.com
            rewriteResponseBody:
              - { type: 'text/html,application/json', match: *origins, replacement: 'http://127.0.0.1:8000/$1', maxChunkSize: 8388608 }
            rewriteRequestHeader:
              - { name: '(?i)^(referer|origin|x-forwarded-host)$', match: '.*', replacement: '' }
            rewriteResponseHeader:
              - { name: '(?i)^location$', match: *origins, replacement: 'http://127.0.0.1:8000/$1' }
              - { name: '(?i)^set-cookie$', match: '(?i)domain=\.?github\.com;?\s*', replacement: '' }
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }
              - { name: '(?i)^strict-transport-security$', match: '.*', replacement: '' }

        # Main site
        - name: github
          matcher:
            rule: PathPrefix(`/github.com/`) || PathPrefix(`/www.github.com/`)
          addr: github.com:443
          tls: { secure: true, serverName: github.com }
          http:
            host: github.com
            rewriteURL:
              - { match: '^/github\.com/', replacement: '/' }   # strip the first segment
            rewriteResponseBody:
              - { type: 'text/html,application/json', match: *origins, replacement: 'http://127.0.0.1:8000/$1', maxChunkSize: 8388608 }
            rewriteRequestHeader:
              - { name: '(?i)^(referer|origin|x-forwarded-host)$', match: '.*', replacement: '' }
            rewriteResponseHeader:
              - { name: '(?i)^location$', match: *origins, replacement: 'http://127.0.0.1:8000/$1' }
              - { name: '(?i)^set-cookie$', match: '(?i)domain=\.?github\.com;?\s*', replacement: '' }
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }
              - { name: '(?i)^strict-transport-security$', match: '.*', replacement: '' }

        # Gist code snippets
        - name: gist
          matcher:
            rule: PathPrefix(`/gist.github.com/`)
          addr: gist.github.com:443
          tls: { secure: true, serverName: gist.github.com }
          http:
            host: gist.github.com
            rewriteURL:
              - { match: '^/gist\.github\.com/', replacement: '/' }
            rewriteResponseBody:
              - { type: 'text/html,application/json', match: *origins, replacement: 'http://127.0.0.1:8000/$1', maxChunkSize: 8388608 }
            rewriteRequestHeader:
              - { name: '(?i)^(referer|origin|x-forwarded-host)$', match: '.*', replacement: '' }
            rewriteResponseHeader:
              - { name: '(?i)^location$', match: *origins, replacement: 'http://127.0.0.1:8000/$1' }
              - { name: '(?i)^set-cookie$', match: '(?i)domain=\.?github\.com;?\s*', replacement: '' }
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }
              - { name: '(?i)^strict-transport-security$', match: '.*', replacement: '' }

        # REST API (JSON)
        - name: api
          matcher:
            rule: PathPrefix(`/api.github.com/`)
          addr: api.github.com:443
          tls: { secure: true, serverName: api.github.com }
          http:
            host: api.github.com
            rewriteURL:
              - { match: '^/api\.github\.com/', replacement: '/' }
            rewriteRequestHeader:
              - { name: '(?i)^(referer|origin|x-forwarded-host)$', match: '.*', replacement: '' }
            rewriteResponseHeader:
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }

        # Static assets (CSS/JS)
        - name: githubassets
          matcher:
            rule: PathPrefix(`/github.githubassets.com/`)
          addr: github.githubassets.com:443
          tls: { secure: true, serverName: github.githubassets.com }
          http:
            host: github.githubassets.com
            rewriteURL:
              - { match: '^/github\.githubassets\.com/', replacement: '/' }
            rewriteRequestHeader:
              - { name: '(?i)^cookie$', match: '.*', replacement: '' }
            rewriteResponseHeader:
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }

        # Raw file content
        - name: raw
          matcher:
            rule: PathPrefix(`/raw.githubusercontent.com/`)
          addr: raw.githubusercontent.com:443
          tls: { secure: true, serverName: raw.githubusercontent.com }
          http:
            host: raw.githubusercontent.com
            rewriteURL:
              - { match: '^/raw\.githubusercontent\.com/', replacement: '/' }
            rewriteRequestHeader:
              - { name: '(?i)^cookie$', match: '.*', replacement: '' }  # prevent cross-origin cookie leak
            rewriteResponseHeader:
              - { name: '(?i)^location$', match: *origins, replacement: 'http://127.0.0.1:8000/$1' }
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }

        # Avatars
        - name: avatars
          matcher:
            rule: PathPrefix(`/avatars.githubusercontent.com/`)
          addr: avatars.githubusercontent.com:443
          tls: { secure: true, serverName: avatars.githubusercontent.com }
          http:
            host: avatars.githubusercontent.com
            rewriteURL:
              - { match: '^/avatars\.githubusercontent\.com/', replacement: '/' }
            rewriteRequestHeader:
              - { name: '(?i)^cookie$', match: '.*', replacement: '' }
            rewriteResponseHeader:
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }

        # Release asset downloads
        - name: release-assets
          matcher:
            rule: PathPrefix(`/release-assets.githubusercontent.com/`)
          addr: release-assets.githubusercontent.com:443
          tls: { secure: true, serverName: release-assets.githubusercontent.com }
          http:
            host: release-assets.githubusercontent.com
            rewriteURL:
              - { match: '^/release-assets\.githubusercontent\.com/', replacement: '/' }
            rewriteRequestHeader:
              - { name: '(?i)^cookie$', match: '.*', replacement: '' }
            rewriteResponseHeader:
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }

        # Repo archive downloads: github.com/<o>/<r>/archive/... 302s here
        - name: codeload
          matcher:
            rule: PathPrefix(`/codeload.github.com/`)
          addr: codeload.github.com:443
          tls: { secure: true, serverName: codeload.github.com }
          http:
            host: codeload.github.com
            rewriteURL:
              - { match: '^/codeload\.github\.com/', replacement: '/' }
            rewriteRequestHeader:
              - { name: '(?i)^cookie$', match: '.*', replacement: '' }
            rewriteResponseHeader:
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }

        # Proxied external images in READMEs/issues
        - name: camo
          matcher:
            rule: PathPrefix(`/camo.githubusercontent.com/`)
          addr: camo.githubusercontent.com:443
          tls: { secure: true, serverName: camo.githubusercontent.com }
          http:
            host: camo.githubusercontent.com
            rewriteURL:
              - { match: '^/camo\.githubusercontent\.com/', replacement: '/' }
            rewriteRequestHeader:
              - { name: '(?i)^cookie$', match: '.*', replacement: '' }
            rewriteResponseHeader:
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }

        # User-uploaded images in issues/PRs/READMEs (legacy upload host)
        - name: user-images
          matcher:
            rule: PathPrefix(`/user-images.githubusercontent.com/`)
          addr: user-images.githubusercontent.com:443
          tls: { secure: true, serverName: user-images.githubusercontent.com }
          http:
            host: user-images.githubusercontent.com
            rewriteURL:
              - { match: '^/user-images\.githubusercontent\.com/', replacement: '/' }
            rewriteRequestHeader:
              - { name: '(?i)^cookie$', match: '.*', replacement: '' }
            rewriteResponseHeader:
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }

        # Social preview / og:image cards
        - name: opengraph
          matcher:
            rule: PathPrefix(`/opengraph.githubassets.com/`)
          addr: opengraph.githubassets.com:443
          tls: { secure: true, serverName: opengraph.githubassets.com }
          http:
            host: opengraph.githubassets.com
            rewriteURL:
              - { match: '^/opengraph\.githubassets\.com/', replacement: '/' }
            rewriteRequestHeader:
              - { name: '(?i)^cookie$', match: '.*', replacement: '' }
            rewriteResponseHeader:
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }

        # GitHub Pages (*.github.io): Host-routed, not SNI-routed — one node serves all subdomains
        - name: githubio
          matcher:
            rule: PathRegexp(`^/[a-z0-9-]+\.github\.io/`)
          addr: github.io:443
          tls: { secure: true, serverName: github.io }
          http:
            hostPattern: '^/([a-z0-9-]+\.github\.io)/'   # extract host from path
            host: '$1'
            rewriteURL:
              - { match: '^/[a-z0-9-]+\.github\.io/', replacement: '/' }
            rewriteRequestHeader:
              - { name: '(?i)^cookie$', match: '.*', replacement: '' }
            rewriteResponseHeader:
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }

log:
  level: info
```

Start it:

```bash
./gost -C gost.yaml
```

## Data Flow

A full round trip to a repository page:

```
GET http://127.0.0.1:8000/github.com/go-gost/gost
  → Sniffer detects HTTP, PathPrefix(`/github.com/`) picks the github node
  → rewriteURL strips the prefix: /github.com/go-gost/gost → /go-gost/gost
  → http.host restores: Host = github.com
  → rewriteRequestHeader deletes Referer/Origin
  → forwarded to https://github.com/go-gost/gost

Response (200 text/html)
  → rewriteResponseBody: https://github.com/... → http://127.0.0.1:8000/github.com/...
  → rewriteResponseHeader:
      Location    → encoded as mirror URL
      Set-Cookie  → strip Domain=github.com
      CSP / HSTS  → deleted
  → returned to client

Client clicks an image link http://127.0.0.1:8000/avatars.githubusercontent.com/u/28017
  → PathPrefix(`/avatars.githubusercontent.com/`) picks the avatars node
  → strip prefix + restore Host → forwarded to https://avatars.githubusercontent.com/u/28017

Client visits a Pages site http://127.0.0.1:8000/microsoft.github.io/
  → PathRegexp(`^/[a-z0-9-]+\.github\.io/`) picks the githubio node
  → hostPattern extracts Host = microsoft.github.io (SNI remains static github.io)
  → rewriteURL strips the prefix: /microsoft.github.io/ → /
  → forwarded to https://github.io/ with Host: microsoft.github.io
```

## Caching

Every mirror request round-trips to GitHub, and pages are large with many assets; repeated round-trips are both slow and wasteful. GOST's [HTTP response cache](https://latest.gost.run/en/tutorials/http-cache/) adds a caching layer so hits return locally without touching the upstream.

The key is a seemingly contradictory point: GitHub sends `Cache-Control: max-age=0, private` on page responses, so **caching by that header by default caches nothing**. But for an anonymous read-only mirror this is precisely what makes it safe — all users see the same public content, with no per-user private data, so cross-user hits leak nothing. Hence we explicitly ignore the upstream `Cache-Control` and use our own TTL.

Three changes to the config above are all it takes:

```yaml
services:
  - name: github-mirror
    addr: :8000
    cache: mirror-cache        # ① service level: reference a named cache store
    handler:
      type: tcp
      metadata:
        sniffing: true
        # ② cache policy (handler metadata)
        cache.ttl: 10m          # default TTL (when no status override)
        cache.status.200: 30m   # 200 (pages/JSON/assets) live longer
        cache.serveStale: true  # serve stale cache as fallback on upstream failure
        cache.maxBodyBytes: 8388608  # 8MB cap; larger raw/release files are not cached

# ③ named cache store: in-memory backend + LRU eviction
caches:
  - name: mirror-cache
    memory:
      maxBytes: 268435456   # 256MB total byte cap, LRU eviction beyond it
      eviction: lru
```

* `cache.ttl` / `cache.status.<code>` control the lifetime of each response class; for anonymous public content, caching pages for 30 minutes is usually harmless.
* `cache.serveStale` falls back to an expired entry when GitHub is unreachable — especially useful for a mirror, so users can still read content during an upstream blip.
* `cache.maxBodyBytes` caps the size of a single cached response; anything larger is passed through uncached to avoid stuffing big files into memory.

> The cache key is computed from the request's Method + Host + RequestURI. Because the return route encodes the upstream domain into the path, same-named requests on different upstream domains naturally never collide.

## Boundaries

This approach serves **anonymous read-only browsing** — public repos, READMEs, avatars, raw files, archive downloads. The following are out of scope and not deliberately accommodated:

* **Login state** — the login flow has multiple hard breaks: the CAPTCHA third-party iframe, WebAuthn's `rpId` bound to the origin, and Secure cookies requiring HTTPS, all of which an HTTP mirror cannot close the loop on.
* **JS runtime-injected URLs** — addresses assembled by scripts at runtime cannot be covered by static rewriting; they need a heavier solution.
* **Standalone sites like `docs.github.com`** — it has its own set of asset origins, and a partial mirror is worse than none, so it's simply excluded.

The value of a mirror is "you can browse, read, and download" — not to fully replicate a logged-in SaaS. Holding that boundary, covering the most content with the fewest mechanisms, is exactly the elegance of reverse-proxy mirroring.
