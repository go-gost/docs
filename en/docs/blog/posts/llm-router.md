---
authors:
  - ginuerzh
categories:
  - Tutorial
  - LLM
  - AI
readtime: 15
date: 2026-07-03
comments: true
---

# Smart LLM API Routing with GOST Reverse Proxy

AI is getting increasingly popular, with more and more LLMs and providers emerging. But tokens remain a finite resource, and single-provider limits are easily reached. Multi-provider combinations with dynamic model-based routing are becoming a more cost-effective approach.

<!-- more -->

## Protocol Conversion and Model Routing

Most mainstream model APIs fall into a few categories:

* **OpenAI Chat** — `/v1/chat/completions`, the default API format for many providers.
* **OpenAI Responses** — `/v1/responses`, currently used by Codex.
* **Anthropic Messages** — `/v1/messages`, currently used by Claude Code.

The challenge becomes connecting clients like Claude Code and Codex to various providers that support these compatible APIs.

### Protocol Conversion

Different providers offer different APIs. For example, DeepSeek's official API provides OpenAI Chat and Anthropic Messages compatibility, but not OpenAI Responses — so it can't be used with Codex directly. OpenCode-Go's DeepSeek only provides an OpenAI Chat interface, which neither Claude Code nor Codex can use directly. This mismatch is the biggest obstacle to model routing.

If we set aside the complexity of protocol conversion, at the API level a model API call is simply a standard HTTP request. From this perspective, LLM API routing becomes pure HTTP protocol conversion — exactly what a reverse proxy does.

HTTP protocol conversion has three layers:

#### Host and URI Rewriting

Clients typically use standard URIs — Claude Code uses `/v1/messages`, Codex uses `/v1/responses`. But providers may use different URIs — DeepSeek uses `/anthropic/v1/messages`, OpenCode-Go uses `/zen/go/v1/chat/completions`. The reverse proxy rewrites the Host and URI based on the target provider's API endpoint.

#### Request Header Modification

API calls require API key authentication. When combining multiple providers, the client can't specify the API key directly. Since authentication is in the HTTP `Authorization` header, the reverse proxy must set the appropriate API key for each provider.

#### Request/Response Body Transformation

This is the most complex and important part — protocol conversion between different API formats, such as converting an Anthropic Messages request to an OpenAI Chat request and converting the response back.

All three conversion layers are completely transparent to the client — the client simply points its model URL to the reverse proxy.

### Model Routing

Clients like Claude Code and Codex typically provide model switching. Claude Code currently offers Fable, Opus, Sonnet, and Haiku models. Codex offers gpt-5.5, gpt-5.4, gpt-5.3, gpt-5.2. The common approach is to configure model mappings on the client side. For more flexibility, the reverse proxy can handle model selection dynamically.

For example, mapping the `model` field in the request body: `claude-fable` → OpenCode-Go's `glm-5.2`, `claude-opus` → DeepSeek's `deepseek-v4-pro`, etc. Adjusting mappings only requires changing the reverse proxy configuration — transparent to clients.

## GOST Reverse Proxy

Unlike dedicated LLM gateways, GOST's [reverse proxy](https://latest.gost.run/tutorials/reverse-proxy/) is a general-purpose port forwarding service that doesn't couple with any specific business logic (LLM routing). It provides the following features:

### Host and URI Rewriting

```yaml
hops:
- name: hop-0
  nodes:
  - name: opencode-go-deepseek
    addr: opencode.ai:443
    http:
      host: opencode.ai
      rewriteURL:
      - match: /v1/messages
        replacement: /zen/v1/chat/completions
      - match: /v1/responses
        replacement: /zen/v1/chat/completions
```

### Custom Request Headers

```yaml
hops:
- name: hop-0
  nodes:
  - name: opencode-go-deepseek
    addr: opencode.ai:443
    http:
      requestHeader:
        Authorization: "Bearer your-opencode-api-key"
```

### Request/Response Body Rewriting

GOST provides a [Rewriter](https://latest.gost.run/concepts/rewriter/) plugin for rewriting request/response bodies, implemented externally via plugins:

```yaml
hops:
- name: hop-0
  nodes:
  - name: opencode-go-deepseek
    addr: opencode.ai:443
    http:
      rewriteRequestBody:
      - rewriter: openai-converter
      rewriteResponseBody:
      - rewriter: openai-converter

rewriters:
- name: openai-converter
  plugin:
    type: http
    addr: http://localhost:8000/rewrite
```

GOST provides an LLM API conversion Rewriter plugin service — [llm-api-converter](https://github.com/ginuerzh/llm-api-converter):

```bash
./llm-api-converter \
  --addr :8000 \
  --model deepseek-v4-flash \
  --model-map "claude-fable=glm-5.2:openai,claude-opus=deepseek-v4-pro:openai,*=deepseek-v4-flash:openai"
```

For simple field replacements (like renaming a model field), use the `json:` prefix in `match` with sjson-based replacement — no external rewriter needed:

```yaml
hops:
- name: hop-0
  nodes:
  - name: opencode-go-deepseek
    addr: opencode.ai:443
    http:
      rewriteRequestBody:
      - match: json:model
        replacement: deepseek-v4-pro
```

### Request Body Matching

Nodes can use matching rules to select providers:

```yaml
hops:
- name: hop-0
  nodes:
  - name: opencode-go-deepseek
    addr: opencode.ai:443
    matcher:
      rule: 'Method(`POST`) && Header(`Content-Type`, `application/json`) && BodyJSON(`output_config.effort`, `^(xhigh|max)$`)'
      bodySize: 65536
```

!!! tip "BodyJSON"
    For JSON request bodies, prefer `BodyJSON(path, regex)` for cleaner expressions without JSON syntax details in the regex. The first argument is a dot-separated JSON path, the second is a regex matched against that field's value.
    ```yaml
    # Match by model field
    matcher:
      rule: 'BodyJSON(`model`, `claude-opus.*`) || BodyJSON(`model`, `gpt-5.4.*`)'
      bodySize: 65536
    
    # Match by Anthropic thinking effort
    matcher:
      rule: 'BodyJSON(`output_config.effort`, `^(xhigh|max)$`)'
      bodySize: 65536
    ```

## Complete Example

Integration with OpenCode-Go and OpenCode-Zen, routing by Anthropic thinking effort:

```yaml
services:
  - name: llm-proxy
    addr: :8787
    handler:
      type: tcp
      metadata:
        sniffing: true
    listener:
      type: tcp
    forwarder:
      hop: hop-0

hops:
  - name: hop-0
    nodes:
      - name: opencode-go-glm-5.2
        addr: opencode.ai:443
        matcher:
          rule: 'Method(`POST`) && Header(`Content-Type`, `application/json`) && BodyJSON(`output_config.effort`, `^(xhigh|max)$`)'
          bodySize: 65536
        tls:
          secure: true
          serverName: opencode.ai
        http:
          host: opencode.ai
          rewriteURL:
            - match: /v1/messages
              replacement: /zen/go/v1/chat/completions
            - match: /v1/responses
              replacement: /zen/go/v1/chat/completions
          requestHeader:
            Authorization: "Bearer your-opencode-apikey"
          rewriteRequestBody:
            - rewriter: openai-converter
          rewriteResponseBody:
            - rewriter: openai-converter

      - name: opencode-go-deepseek-v4-pro
        addr: opencode.ai:443
        matcher:
          rule: 'Method(`POST`) && Header(`Content-Type`, `application/json`) && BodyJSON(`output_config.effort`, `^(low|medium|high)$`)'
          bodySize: 65536
        tls:
          secure: true
          serverName: opencode.ai
        http:
          host: opencode.ai
          rewriteURL:
            - match: /v1/messages
              replacement: /zen/go/v1/chat/completions
            - match: /v1/responses
              replacement: /zen/go/v1/chat/completions
          requestHeader:
            Authorization: "Bearer your-opencode-apikey"
          rewriteRequestBody:
            - rewriter: openai-converter
          rewriteResponseBody:
            - rewriter: openai-converter

      - name: opencode-zen-deepseek-v4-flash-free
        addr: opencode.ai:443
        matcher:
          rule: 'Method(`HEAD`) || Method(`POST`) && Header(`Content-Type`, `application/json`)'
        tls:
          secure: true
          serverName: opencode.ai
        http:
          host: opencode.ai
          rewriteURL:
            - match: /v1/messages
              replacement: /zen/v1/chat/completions
            - match: /v1/responses
              replacement: /zen/v1/chat/completions
            - match: /
              replacement: /zen
          requestHeader:
            Authorization: "Bearer your-opencode-apikey"
          rewriteRequestBody:
            - rewriter: openai-converter
          rewriteResponseBody:
            - rewriter: openai-converter

rewriters:
  - name: openai-converter
    plugin:
      type: http
      addr: http://localhost:8000/rewrite
```

Start the services:

```bash
./gost -C gost.yaml
./llm-api-converter \
  --addr :8000 \
  --model-map "gpt-5.5=glm-5.2:openai,claude-fable=glm-5.2:openai,gpt-5.4=deepseek-v4-pro:openai,claude-opus=deepseek-v4-pro:openai,gpt-5.3=deepseek-v4-flash:openai,claude-sonnet=deepseek-v4-flash:openai,*=deepseek-v4-flash-free:openai"
```

### Data Flow

**High effort (xhigh/max) — routed to strong model:**
```
POST :8787/v1/messages (output_config.effort: "xhigh")
  → Sniffer reads HTTP Body prefix
  → BodyJSON("output_config.effort") matches "(xhigh|max)" → selects opencode-go-glm-5.2
  → rewriteURL: /v1/messages → /zen/go/v1/chat/completions
  → rewriteRequestBody: openai-converter rewrites protocol + model
  → Forward to https://opencode.ai/zen/go/v1/chat/completions
```

**Low/medium/high effort — routed to standard model:**
```
POST :8787/v1/messages (output_config.effort: "medium")
  → BodyJSON("output_config.effort") matches "(low|medium|high)" → selects opencode-go-deepseek-v4-pro
  → Forward to https://opencode.ai/zen/go/v1/chat/completions
```

**No effort / HEAD request — catch-all:**
```
HEAD :8787/v1/models
  → Method(`HEAD`) → selects opencode-zen-deepseek-v4-flash-free
  → rewriteURL: /v1/models → /zen/v1/models
  → Forward to https://opencode.ai/zen/v1/models
```

### Docker Compose

```yaml
services:
  gost:
    image: gogost/gost
    ports:
      - "8787:8787"
    volumes:
      - ./gost.yaml:/etc/gost/gost.yaml
    depends_on:
      - llm-converter

  llm-converter:
    image: ginuerzh/llm-api-converter
    command:
      - --addr=:8000
      - --model-map=gpt-5.5=glm-5.2:openai,claude-fable=glm-5.2:openai,...
    ports:
      - "8000:8000"
```

> Note: In Docker Compose, services communicate by container name, so change the rewriter address to `http://llm-converter:8000/rewrite`.

Start:

```bash
docker compose up -d
```
