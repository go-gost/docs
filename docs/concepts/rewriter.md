---
comments: true
---

# 重写器

:material-tag: 3.3.0

重写器可以对HTTP请求和响应体进行动态修改，与内置的`rewriteBody`/`rewriteResponseBody`/`rewriteRequestBody`规则（基于正则匹配和替换）不同，重写器通过外部[插件](plugin.md)服务提供更灵活的修改能力。

## 使用重写器

重写器可以作为服务级配置，在`services`中引用：

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

### 插件配置

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

重写器也可以在每个转发器节点的`rewriteBody`/`rewriteResponseBody`/`rewriteRequestBody`规则中使用：

```yaml
forwarder:
  nodes:
  - name: target-0
    addr: example.com:80
    http:
      rewriteResponseBody:
      - type: text/html
        rewriter: rewriter-0
      rewriteRequestBody:
      - type: application/json
        rewriter: rewriter-0
```

当规则设置了`rewriter`后，body的修改将委托给重写器插件处理，`match`和`replacement`将被忽略。

`rewriter`可以与`type`(内容类型过滤)结合使用，通过设置不同的`type`将不同类型的请求/响应体发送给不同的重写器处理。
