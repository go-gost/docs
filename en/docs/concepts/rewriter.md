---
comments: true
---

# Rewriter

:material-tag: 3.3.0

The Rewriter can dynamically modify HTTP request and response bodies. Unlike the built-in `rewriteBody`/`rewriteResponseBody`/`rewriteRequestBody` rules (based on regex matching and replacement), the rewriter provides more flexible modification capabilities through external [plugin](plugin.md) services. The rewriter can also handle HTTP headers (`rewriteRequestHeader`/`rewriteResponseHeader`), in which case the entire header block is serialized to text and delegated to the plugin.

## Plugin Configuration

A rewriter plugin is configured under `rewriters` and referenced by name in forwarder node rewrite rules.

`plugin.type` (string, default=grpc)
:    plugin type: `grpc` or `http`.

`plugin.addr` (string, required)
:    plugin server address.

`plugin.token` (string)
:    credentials for server-side authentication.

`plugin.tls` (object)
:    enable TLS encryption for the plugin connection.

`plugin.timeout` (duration)
:    request timeout.

### HTTP Plugin

```yaml
rewriters:
- name: rewriter-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/rewrite
```

Request format:
```json
{"data":"<base64 original content>","metadata":<metadata>}
```

Response format:
```json
{"ok":true,"data":"<base64 modified content>"}
```

## Node-Level Rewriter

The rewriter is used in each forwarder node's `rewriteBody`/`rewriteResponseBody`/`rewriteRequestBody` rules:

```yaml
forwarder:
  nodes:
  - name: target-0
    addr: example.com:80
    http:
      rewriteResponseBody:
      - type: text/html
        match: "Hello"
        replacement: "Hola"
      rewriteRequestBody:
      - type: application/json
        rewriter: rewriter-0
```

When a rule has `rewriter` set, the body modification is delegated to the rewriter plugin, and the `match`/`replacement` fields are ignored.

### Header Rewriting

Header rewriting uses the `rewriteRequestHeader`/`rewriteResponseHeader` rules. Each entry has:

- `name` (string) — header-name regex (case-insensitive). In plugin mode it gates whether the plugin is invoked (an empty `name` means always invoke).
- `match` (string) — header-value regex.
- `replacement` (string) — replacement value; an empty result deletes the header.
- `rewriter` (string) — optional external rewriter plugin.

Regex mode replaces each value independently; plugin mode serializes the whole header block to MIME text (`Key: value\r\n`), hands it to the plugin, and parses the returned block back. Metadata carries `kind:"header"` to distinguish it from body rewriting (`kind:"body"`).

```yaml
http:
  rewriteResponseHeader:
  - name: '(?i)^location$'
    match: 'https://example\.com'
    replacement: 'https://127.0.0.1:8000'
  - name: '(?i)^set-cookie$'
    match: '(?i)domain=\.?example\.com;?\s*'
    replacement: ''               # empty value → delete header
  rewriteRequestHeader:
  - name: '(?i)^(referer|origin)$'
    match: '.*'
    replacement: ''               # delete request headers
```

When `rewriter` is not set, the `match` field can be either:

- A **regex** pattern (applied to the raw body bytes via `regexp.ReplaceAll`). The `replacement` value supports Go's regex replacement syntax (`$1`, `$2`, etc.).
- A **`json:` prefix** for JSON path-based field matching: `json:<path>[=<value-regex>]`. The field value is extracted with [gjson](https://github.com/tidwall/gjson) and matched against the optional value regex. When matched, the field is replaced with `replacement` using [sjson](https://github.com/tidwall/sjson).
- A **`json-:` prefix** to delete a JSON field instead of replacing it: `json-:<path>[=<value-regex>]`. When the field value matches the regex, the field is removed via [sjson](https://github.com/tidwall/sjson)'s delete operation and `replacement` is ignored. Note that deleting the last remaining key of an object leaves an empty object (`{}`), consistent with sjson semantics.

```yaml
# Regex mode (existing behavior)
rewriteRequestBody:
- match: '"model"\s*:\s*"[^"]*"'
  replacement: '"model":"deepseek-v4-pro"'

# JSON path mode — match any model field and replace it
rewriteRequestBody:
- match: json:model
  replacement: deepseek-v4-pro

# JSON path mode — match only specific effort values
rewriteRequestBody:
- match: json:output_config.effort=(xhigh|max)
  replacement: low

# JSON delete mode — remove the model field entirely
rewriteRequestBody:
- match: json-:model
```

JSON modes (`json:`/`json-:`) auto-detect `application/json` content type, no `type` field needed.

The `rewriter` can be combined with `type` (content-type filtering) to send different body types to different rewriters.

## Related Tutorial

[Reverse Proxy — Rewrite Request/Response Body](../tutorials/reverse-proxy.md#rewrite-requestresponse-body) demonstrates rewriting HTTP request/response bodies through forwarder node rules.
