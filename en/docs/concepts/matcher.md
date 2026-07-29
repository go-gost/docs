---
comments: true
---

# Matcher

A **matcher** is a routing DSL (Domain Specific Language) that filters requests based on
their attributes — hostname, path, method, headers, client IP, etc. Matchers are used in
multiple places throughout GOST to route traffic conditionally:

| Component | Field | Scope |
|-----------|-------|-------|
| [Node](hop.md) | `matcher.rule` | Selects nodes within a hop |
| [Hop Group](forwarder.md#hop-group) | `hopGroup.hops[].matcher` | Selects hop entries within a forwarder |
| [Chain Group](chain.md#chain-group) | `chainGroup.chains[].matcher` | Selects chain entries within a listener/handler |

In all three places the matcher uses the same DSL and the same routing context.
The available context fields depend on the protocol layer:

| Level | Available fields |
|-------|------------------|
| Node (inside a hop) | `Host`, `Path`, `Method`, `Header`, `Query`, `BodyRegexp`, `BodyJSON`, `ClientIP`, `Network`, `Proto` |
| Hop Group (forwarder) | Same as node — full HTTP request context via `hop.SelectOptions` |
| Chain Group | `Host` — target hostname from the request. `RouteOptions` currently only carries `Host`. |

## DSL Reference

### Boolean Operators

Rules support standard boolean logic:

| Operator | Meaning | Example |
|----------|---------|---------|
| `&&` | AND | `Host("a.com") && PathPrefix("/api/")` |
| `\|\|` | OR | `Host("a.com") \|\| Host("b.com")` |
| `!` | NOT | `!Host("blocked.com")` |
| `()` | Grouping | `(Host("a.com") \|\| Host("b.com")) && PathPrefix("/api/")` |

### Matcher Functions

| Function | Args | Description | Example |
|----------|------|-------------|---------|
| `Host` | `pattern` | Match hostname exactly or by wildcard (also matches SNI for TLS) | `Host("*.example.com")` |
| `HostRegexp` | `regex` | Match hostname against a [Go regexp][re] | `HostRegexp("^api[0-9]+\\.example\\.com$")` |
| `Path` | `pattern` | Match request path exactly | `Path("/api/v1/users")` |
| `PathPrefix` | `prefix` | Match if path starts with prefix | `PathPrefix("/api/")` |
| `PathRegexp` | `regex` | Match path against a [Go regexp][re] | `PathRegexp("\\.(jpeg\\|jpg\\|png)$")` |
| `Method` | `method` | Match HTTP method | `Method("POST")` |
| `Header` | `key` | Match if the HTTP header `key` exists | `Header("Content-Type")` |
| `Header` | `key, value` | Match header `key` value exactly | `Header("Content-Type", "application/json")` |
| `Header` | `key, op, value` | Compare numeric header `key` with [op](#comparison-operators) against `value` [^tag] | `Header("Content-Length", "gt", "1024")` |
| `HeaderRegexp` | `key, regex` | Match header `key` against a [Go regexp][re] | `HeaderRegexp("Content-Type", "^application/(json\\|yaml)$")` |
| `Query` | `key` | Match if the query parameter `key` exists | `Query("page")` |
| `Query` | `key, value` | Match query parameter `key` value exactly | `Query("page", "1")` |
| `Query` | `key, op, value` | Compare numeric query param `key` with [op](#comparison-operators) against `value` [^tag] | `Query("page", "gt", "2")` |
| `QueryRegexp` | `key, regex` | Match query param `key` against a [Go regexp][re] | `QueryRegexp("q", ".*")` |
| `ClientIP` | `ip...` | Match client IP against one or more IPs or CIDRs | `ClientIP("10.0.0.0/8", "::1")` |
| `Network` | `net` | Match connection network type | `Network("tcp")` |
| `Proto` | `protocol` | Match detected application protocol (requires sniffing) | `Proto("http")` |
| `BodyRegexp` | `regex` | Match the buffered request body prefix against a [Go regexp][re] [^body] | `BodyRegexp("\"model\"\\s*:\\s*\"claude-opus[^\"]*\"")` |
| `BodyJSON` | `path, regex` | Extract a JSON field via [GJSON path](https://github.com/tidwall/gjson#path-syntax) and match against a [Go regexp][re] [^body] | `BodyJSON("model", "claude.*")` |
| `BodyJSON` | `path, op, value` | Extract a numeric JSON field via [GJSON path](https://github.com/tidwall/gjson#path-syntax) and compare with [op](#comparison-operators) against `value` [^body] [^tag] | `BodyJSON("age", "ge", "18")` |
| `Admission` | `name` | Delegate to a named admission controller [^tag2] | `Admission("block-internal")` |
| `Bypass` | `name` | Delegate to a named bypass rule [^tag2] | `Bypass("china-mainland")` |

[^tag]: :material-tag: 3.3.0
[^tag2]: :material-tag: 3.2.4
[^body]: Body matchers require `sniffing: true` on the handler. Only a prefix is read for matching (see [Body Size](#body-size)); the full request body is forwarded unchanged. The prefix is automatically decompressed according to `Content-Encoding` (`gzip`, `deflate`, `br`, `zstd`) before matching.
[re]: https://golang.org/pkg/regexp/

<span id="comparison-operators"></span>

#### Comparison Operators

:material-tag: 3.3.0

`Header`, `Query`, and `BodyJSON` accept a 3-parameter form with a comparison operator:
`Header("Content-Length", "gt", "1024")`.

| Operator | Matches when |
|----------|-------------|
| `gt` | value is greater than |
| `ge` | value is greater or equal |
| `lt` | value is less than |
| `le` | value is less or equal |
| `eq` | value is equal |
| `ne` | value is not equal |

The value is parsed as a floating-point number. Non-numeric values are silently skipped
(treated as no match). For multi-value headers and query parameters, the match succeeds
if **any** value satisfies the comparison.

### Priority

`priority` (int, default: auto)
:    To avoid path overlap, nodes are sorted by default in descending order using rule
     length. The priority is directly equal to the length of the rule — the longest rule
     has the highest priority.

     Set `priority` to a specific value to override this. A **negative** value disables
     automatic priority ordering entirely — all matching nodes go through the selector equally.

### Body Size

`bodySize` (int, default: 1MB)
:    Maximum size of the HTTP request body prefix (in bytes) to read for body matchers.
     Defaults to `1MB` (`1048576`). Capped at `10MB` (`10485760`); larger values are clamped.

     Set to `-1` to disable body matching entirely.

     !!! note
         The body prefix is automatically decompressed according to `Content-Encoding`
         (`gzip`, `deflate`, `br`, `zstd`) before matching. Only the prefix used for
         matching is decoded; the full body forwarded to the target keeps its original
         compression.

### Regexp Syntax

Matchers that accept a regexp use [Go's `regexp` syntax](https://golang.org/pkg/regexp/)
(RE2). Perl-style lookahead/lookbehind and backreferences are not supported.

## Examples

### Basic: Route by hostname

```yaml
matcher:
  rule: Host("api.example.com")
```

### With boolean logic

```yaml
matcher:
  rule: 'Method("POST") && PathPrefix("/v1/") && Header("Content-Type", "application/json")'
```

### With body matching

```yaml
matcher:
  rule: 'BodyJSON("output_config.effort", "^(xhigh|max)$")'
  bodySize: 65536
```

### Chain group: route by target hostname

```yaml
chainGroup:
  chains:
  - chain: chain-api
    matcher:
      rule: Host("api.example.com")
  - chain: chain-web
  selector:
    strategy: round
```

### Hop group: route by path prefix

```yaml
hopGroup:
  hops:
  - hop: hop-api
    matcher:
      rule: 'PathPrefix("/api/") && Host("*.example.com")'
  - hop: hop-internal
    matcher:
      rule: 'ClientIP("10.0.0.0/8", "172.16.0.0/12")'
  - hop: hop-default
  selector:
    strategy: rr
```

## See Also

- [Reference: Node Matcher fields](../reference/configuration/file.md#node-matcher) — YAML field reference for `matcher` on nodes
- [Selector](selector.md) — how nodes/entries are selected after matcher filtering
- [Forwarder](forwarder.md) — hop group with matcher-based routing
- [Chain](chain.md) — chain group with matcher-based routing
