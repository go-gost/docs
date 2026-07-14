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

# 基于GOST反向代理实现大模型API的智能路由

AI越来越火，相应的大模型也越来越多，对应的大模型供应商也是百花齐放，但现实是Token仍旧是有限资源，单一供应商的限制触手可及。于是多供应商的组合使用，根据模型名动态分配，越来越成为更具性价比的方案。

<!-- more -->

## 协议转换与模型路由

好在目前主流的模型API种类不多，最常使用的几种：

* OpenAI Chat - `/v1/chat/completions` 许多大模型供应商默认提供的API接口格式。
* OpenAI Responses - `/v1/responses` 目前Codex使用的API。
* Anthropic Messages - `/v1/messages` 目前Claude Code使用的API。

于是对接不同的供应商模型就转变成了让Claude Code, Codex等使用大模型API的客户端对接以上三种供应商兼容的API。

### 协议转换

不同的供应商开放的API种类不一，例如DeepSeek官方目前只提供了OpenAI Chat和Anthropic Messages兼容的AI，但没有提供OpenAI Responses API，因此无法直接接入Codex使用。OpenCode-Go中的DeepSeek目前却只提供了OpenAI Chat接口，Claude Code和Codex都无法直接使用。这种客户端使用的接口与模型供应商提供的接口不一致性，是模型路由的最大障碍，也是大模型API路由重点要解决的问题。

如果先不考虑以上接口转换的复杂性，单纯看API层面，一次模型接口的调用就是一次标准的HTTP请求。从这个角度考虑，大模型API路由就变成了纯HTTP协议的转换，也正是反向代理的功能。

这里的HTTP协议转换分为三层：

#### 请求主机和URI的转换

客户端一般默认使用标准URI，例如Claude Code使用`/v1/messages`，Codex使用`/v1/responses`。但是模型供应商可能使用的是不同的URI，例如DeepSeek使用`/anthropic/v1/messsages`，OpenCode-Go使用`/zen/go/v1/chat/completions`。反向代理在接收到客户端的请求后需要根据具体的模型供应商提供的API端点，修改请求的Host和URI。

#### 请求头的修改

模型API的调用需要提供apikey认证信息，在组合使用不同供应商时，apikey就不能由客户端来指定了。由于认证信息是放在HTTP请求头中的`Authorization`字段，因此反向代理需要根据不同供应商分别将对应的apikey设置到请求头中。

#### 请求/响应体的转换

这一步正是上面提到的最复杂也最重要的部分，不同协议之间的接口转换。例如将Anthrpoic Messages的请求转成OpenAI Chat请求，再将OpenAI Chat的响应转成Anthropic Messages的响应。

以上三层的转换对于客户端是完全透明无感知的，客户端只需将其模型URL指向反向代理服务即可。

### 模型路由

Claude Code和Codex等客户端一般都提供了模型切换功能，例如Claude Code目前提供了Fable，Opus，Sonnet，Haiku四种模型，Codex也提供了gpt-5.5，gpt-5.4，gpt-5.3，gpt-5.2四种模型。一般的做法是在客户端直接设置模型映射，但为了让使用上更灵活和更方便，模型的选择可以由反向代理动态选择。

例如根据请求体中的`model`字段值可以设置对应的模型映射与供应商路由，claude-fable映射到OpenCode-Go的glm-5.2，claude-opus映射到DeepsSeek的deepseek-v4-pro等。如果需要调整映射，只需修改反向代理配置，同样对于客户端是无感知的。

## GOST反向代理

与市面上已经存在的大模型专用网关不同，GOST[反向代理](https://latest.gost.run/tutorials/reverse-proxy/)本身仅是一个通用的端口转发服务，不与任何特定的具体业务(LLM路由)耦合，其通过以下提供的功能来解决上面的问题。

### 修改Host与URI

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

通过`http.host`将请求的Host替换为`opencode.ai`。

通过`http.rewriteURL`指定URI重写规则。

### 自定义请求头

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

通过`http.requestHeader`注入对应供应商提供的apikey。

### 修改请求/响应体

GOST提供了[Rewriter](https://latest.gost.run/concepts/rewriter/)插件功能，反向代理通过使用插件来提供对请求/响应的重写功能。在这里是将协议转换部分完全独立出去交由插件实现。

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

通过`http.rewriteRequestBody`来指定请求体重写的规则，可以使用rewriter插件。

通过`http.rewriteResponseBody`来指定响应体重写的规则，可以使用rewriter插件。

GOST已经提供了一个大模型API转换的Rewriter插件服务[llm-api-converter](https://github.com/ginuerzh/llm-api-converter)，可以直接使用。

```bash
# claude-fable* -> glm-5.2(OpenAI Chat)
# claude-opus* -> deepseek-v4-pro (OpenAI Chat)
# catch-all fallback (*) -> deepseek-v4-flash (OpenAI Chat)
./llm-api-converter \
  --addr :8000 \
  --model deepseek-v4-flash \
  --model-map "claude-fable=glm-5.2:openai,claude-opus=deepseek-v4-pro:openai,*=deepseek-v4-flash:openai"
```

### 请求体匹配规则

GOST通过在节点上提供匹配规则来选择对应的节点实现供应商选择

```yaml
hops:
- name: hop-0
  nodes:
  - name: opencode-go-deepseek
    addr: opencode.ai:443
    matcher:
      rule: '(BodyRegexp(`"model"\s*:\s*"claude-opus[^"]*"`) || BodyRegexp(`"model"\s*:\s*"gpt-5.4[^"]*"`))'
      bodySize: 65536
```

通过`matcher.rule`中使用`BodyRegexp`来匹配HTTP请求体的模型名，对于以上配置规则匹配`model`字段以`claude-opus`或`gpt-5.4`为前缀的请求。

GOST的反向代理服务通过以上功能便可以灵活的对接任何协议兼容的大模型供应商，同时提供给Claude Code，Codex等客户端使用。

## 示例

以OpenCode为例，以下是一个完整的对接OpenCode-Go和OpenCode-Zen方案。

对于`claude-fable`和`gpt-5.5`模型前缀，路由到OpenCode-Go并使用`glm-5.2`模型。

对于`claude-opus`和`gpt-5.4`模型前缀，路由到OpenCode-Go并使用`deepseek-v4-pro`模型。

对于`claude-sonnet`和`gpt-5.3`模型前缀，路由到OpenCode-Go并使用`deepseek-v4-flash`模型。

其他模型，路由到OpenCode-Zen并使用`deepseek-v4-flash-free`模型。

```yaml
# gost.yaml
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
          rule: 'Method(`POST`) && Header(`Content-Type`, `application/json`) && (BodyRegexp(`"model"\s*:\s*"claude-fable[^"]*"`) || BodyRegexp(`"model"\s*:\s*"gpt-5.5[^"]*"`))'
          bodySize: 65536
        tls:
          secure: true
          serverName: opencode.ai
        http:
          host: opencode.ai
          rewriteURL:
            - match: /v1/messages   # Anthropic Messages API
              replacement: /zen/go/v1/chat/completions
            - match: /v1/responses # OpenAI Responses API
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
          rule: 'Method(`POST`) && Header(`Content-Type`, `application/json`) && (BodyRegexp(`"model"\s*:\s*"claude-opus[^"]*"`) || BodyRegexp(`"model"\s*:\s*"gpt-5.4[^"]*"`))'
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

      - name: opencode-go-deepseek-v4-flash
        addr: opencode.ai:443
        matcher:
          rule: 'Method(`POST`) && Header(`Content-Type`, `application/json`) && (BodyRegexp(`"model"\s*:\s*"claude-sonnet[^"]*"`) || BodyRegexp(`"model"\s*:\s*"gpt-5.3[^"]*"`))'
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
            - match: /v1/models
              replacement: /zen/v1/models
            - match: /v1
              replacement: /zen/v1
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

GOST反向代理服务

```bash
./gost -C gost.yaml
```

Rewriter插件服务，负责模型映射与协议转换

```bash
./llm-api-converter \
  --addr :8000 \
  --model-map "gpt-5.5=glm-5.2:openai,claude-fable=glm-5.2:openai,gpt-5.4=deepseek-v4-pro:openai,claude-opus=deepseek-v4-pro:openai,gpt-5.3=deepseek-v4-flash:openai,claude-sonnet=deepseek-v4-flash:openai,*=deepseek-v4-flash-free:openai"
```

### 数据流

#### Anthropic Messages 客户端（Claude Code）

```
POST :8787/v1/messages (model: claude-opus-4-8)
  → Sniffer 嗅探 HTTP，读取 Body 前缀
  → BodyRegexp 匹配 "claude-opus" → 选中 opencode-go-deepseek-v4-pro 节点
  → rewriteURL: /v1/messages → /zen/go/v1/chat/completions
  → rewriteRequestBody: openai-converter 转换协议 + model 替换为 deepseek-v4-pro
  → 转发至 https://opencode.ai/zen/go/v1/chat/completions
```

#### OpenAI Responses 客户端（Codex）

```
POST :8787/v1/responses (model: gpt-5.5)
  → Sniffer 嗅探 HTTP，读取 Body 前缀
  → BodyRegexp 匹配 "gpt-5.5" → 选中 opencode-go-glm-5.2 节点
  → rewriteURL: /v1/responses → /zen/go/v1/chat/completions
  → rewriteRequestBody: openai-converter 转换协议 + model 替换为 glm-5.2
  → 转发至 https://opencode.ai/zen/go/v1/chat/completions
```

#### 兜底（其他请求）

```
POST :8787/v1/messages (model: claude-haiku-5)
  → Sniffer 嗅探 HTTP，读取 Body 前缀
  → 命中 兜底规则 → 选中 opencode-zen-deepseek-v4-flash-free 节点
  → rewriteURL: /v1/messages → /zen/v1/chat/completions
  → rewriteRequestBody: openai-converter 转换协议 + model 替换为 deepseek-v4-flash-free
  → 转发至 https://opencode.ai/zen/v1/chat/completions
```

### Docker Compose

使用 Docker Compose 部署 GOST 与 llm-api-converter 重写插件：

```yaml
# docker-compose.yml
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
      - --model-map=gpt-5.5=glm-5.2:openai,claude-fable=glm-5.2:openai,gpt-5.4=deepseek-v4-pro:openai,claude-opus=deepseek-v4-pro:openai,gpt-5.3=deepseek-v4-flash:openai,claude-sonnet=deepseek-v4-flash:openai,*=deepseek-v4-flash-free:openai
    ports:
      - "8000:8000"
```

> 注意：Docker Compose 中服务间通过容器名通信，需将 gost.yaml 中的 rewriter 地址改为 `http://llm-converter:8000/rewrite`。

启动：

```bash
docker compose up -d
```

