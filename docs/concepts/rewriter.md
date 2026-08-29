---
comments: true
---

# 重写器

:material-tag: 3.3.0

重写器可以对HTTP请求和响应体进行动态修改，与内置的`rewriteBody`/`rewriteResponseBody`/`rewriteRequestBody`规则（基于正则匹配和替换）不同，重写器通过外部[插件](plugin.md)服务提供更灵活的修改能力。重写器同样可以处理HTTP头（`rewriteRequestHeader`/`rewriteResponseHeader`），此时整个头块会被序列化为文本并委托给插件。

## 插件配置

重写器插件在`rewriters`中配置，并在转发器节点重写规则中按名称引用。

`plugin.type` (string, default=grpc)
:    插件类型：`grpc`，`http`。

`plugin.addr` (string, required)
:    插件服务地址。

`plugin.token` (string)
:    认证信息，插件服务可以选择对此信息进行验证。

`plugin.tls` (object)
:    设置后将使用TLS加密传输。

`plugin.timeout` (duration)
:    请求超时时长。

### HTTP插件

```yaml
rewriters:
- name: rewriter-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/rewrite
```

请求体格式：
```json
{"data":"<base64原内容>","metadata":<元数据>}
```

响应体格式：
```json
{"ok":true,"data":"<base64修改后内容>"}
```

## 节点级重写器

重写器在每个转发器节点的`rewriteBody`/`rewriteResponseBody`/`rewriteRequestBody`规则中使用：

```yaml
forwarder:
  nodes:
  - name: target-0
    addr: example.com:80
    http:
      rewriteResponseBody:
      - type: text/html
        match: "Hello"
        replacement: "你好"
      rewriteRequestBody:
      - type: application/json
        rewriter: rewriter-0
```

当规则设置了`rewriter`后，body的修改将委托给重写器插件处理，`match`和`replacement`将被忽略。

### 头重写

头重写通过`rewriteRequestHeader`/`rewriteResponseHeader`规则实现。每项包含：

- `name` (string) — 头名正则（大小写不敏感）。插件模式下作为是否调用插件的门控（`name` 为空表示始终调用）。
- `match` (string) — 头值正则。
- `replacement` (string) — 替换值；替换结果为空则删除该头。
- `rewriter` (string) — 可选的外部 rewriter 插件。

正则模式逐值独立替换；插件模式将整个头块序列化为 MIME 文本（`Key: value\r\n`）后交给插件，插件返回修改后的头块文本再解析回。元数据中包含 `kind:"header"` 以区别于 body 重写（`kind:"body"`）。

```yaml
http:
  rewriteResponseHeader:
  - name: '(?i)^location$'
    match: 'https://example\.com'
    replacement: 'https://127.0.0.1:8000'
  - name: '(?i)^set-cookie$'
    match: '(?i)domain=\.?example\.com;?\s*'
    replacement: ''               # 值空 → 删头
  rewriteRequestHeader:
  - name: '(?i)^(referer|origin)$'
    match: '.*'
    replacement: ''               # 删除请求头
```

当不使用`rewriter`时，`match`字段可以是：

- **正则表达式**（对原始 body 字节进行 `regexp.ReplaceAll` 替换）。`replacement` 支持 Go 正则替换语法（`$1`、`$2` 等）。
- **`json:` 前缀**用于 JSON 路径字段匹配：`json:<路径>[=<值正则>]`。字段值通过 [gjson](https://github.com/tidwall/gjson) 提取后与可选的值正则匹配，命中后通过 [sjson](https://github.com/tidwall/sjson) 替换。
- **`json-:` 前缀**用于删除 JSON 字段：`json-:<路径>[=<值正则>]`。字段值匹配正则时，使用 [sjson](https://github.com/tidwall/sjson) 的删除操作移除该字段，`replacement` 会被忽略。注意：删除对象最后一个键后会留下空对象 `{}`，这是 sjson 的语义。

```yaml
# 正则模式（现有行为）
rewriteRequestBody:
- match: '"model"\s*:\s*"[^"]*"'
  replacement: '"model":"deepseek-v4-pro"'

# JSON 路径模式 — 匹配任意 model 字段并替换
rewriteRequestBody:
- match: json:model
  replacement: deepseek-v4-pro

# JSON 路径模式 — 仅匹配特定 effort 值
rewriteRequestBody:
- match: json:output_config.effort=(xhigh|max)
  replacement: low

# JSON 删除模式 — 直接删除 model 字段
rewriteRequestBody:
- match: json-:model
```

JSON 模式（`json:`/`json-:`）自动检测 `application/json` 内容类型，无需设置 `type`。

`rewriter`可以与`type`(内容类型过滤)结合使用，通过设置不同的`type`将不同类型的请求/响应体发送给不同的重写器处理。

## 相关教程

[反向代理 — 重写请求体和响应体](../tutorials/reverse-proxy.md#重写请求体和响应体) 演示了如何通过转发器节点规则重写 HTTP 请求/响应体。
