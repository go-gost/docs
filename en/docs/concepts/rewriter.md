---
comments: true
---

# Rewriter

:material-tag: 3.3.0

The Rewriter can dynamically modify HTTP request and response bodies. Unlike the built-in `rewriteBody`/`rewriteResponseBody`/`rewriteRequestBody` rules (based on regex matching and replacement), the rewriter provides more flexible modification capabilities through external [plugin](plugin.md) services.

## Using a Rewriter

The rewriter can be configured at the service level and referenced in `services`:

```yaml
services:
- name: service-0
  addr: :8080
  handler:
    type: auto
  listener:
    type: tcp
  rewriter: rewriter-0

rewriters:
- name: rewriter-0
  plugin:
    type: grpc
    addr: 127.0.0.1:8000
```

### Plugin Configuration

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

The rewriter can also be used in each forwarder node's `rewriteBody`/`rewriteResponseBody`/`rewriteRequestBody` rules:

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

When `rewriter` is not set, the `match` field can be either:

- A **regex** pattern (applied to the raw body bytes via `regexp.ReplaceAll`). The `replacement` value supports Go's regex replacement syntax (`$1`, `$2`, etc.).
- A **`json:` prefix** for JSON path-based field matching: `json:<path>[=<value-regex>]`. The field value is extracted with [gjson](https://github.com/tidwall/gjson) and matched against the optional value regex. When matched, the field is replaced with `replacement` using [sjson](https://github.com/tidwall/sjson).

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
```

JSON mode auto-detects `application/json` content type, no `type` field needed.

The `rewriter` can be combined with `type` (content-type filtering) to send different body types to different rewriters.
