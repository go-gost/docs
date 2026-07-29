---
comments: true
---

# 匹配器

**匹配器**是一种路由DSL（领域特定语言），根据请求的属性（主机名、路径、方法、请求头、客户端IP等）来过滤请求。匹配器在GOST的多个地方使用，用于按条件路由流量：

| 组件 | 字段 | 作用范围 |
|------|------|---------|
| [节点](hop.md) | `matcher.rule` | 在跳跃点内选择节点 |
| [跳跃点组](forwarder.md#_4) | `hopGroup.hops[].matcher` | 在转发器内选择跳跃点条目 |
| [转发链组](chain.md#_6) | `chainGroup.chains[].matcher` | 在监听器/处理器内选择转发链条目 |

匹配器在所有三个位置使用相同的DSL和相同的路由上下文。可用的上下文字段取决于协议层：

| 层级 | 可用字段 |
|------|---------|
| 节点（跳跃点内） | `Host`、`Path`、`Method`、`Header`、`Query`、`BodyRegexp`、`BodyJSON`、`ClientIP`、`Network`、`Proto` |
| 跳跃点组（转发器） | 与节点相同 — 通过 `hop.SelectOptions` 传递完整的HTTP请求上下文 |
| 转发链组 | `Host` — 请求的目标主机名。`RouteOptions` 当前仅携带 `Host` |

## DSL参考

### 布尔运算符

规则支持标准布尔逻辑：

| 运算符 | 含义 | 示例 |
|--------|------|------|
| `&&` | 与 | `Host("a.com") && PathPrefix("/api/")` |
| `\|\|` | 或 | `Host("a.com") \|\| Host("b.com")` |
| `!` | 非 | `!Host("blocked.com")` |
| `()` | 分组 | `(Host("a.com") \|\| Host("b.com")) && PathPrefix("/api/")` |

### 匹配函数

| 函数 | 参数 | 说明 | 示例 |
|------|------|------|------|
| `Host` | `pattern` | 精确或通配符匹配主机名（TLS时也匹配SNI） | `Host("*.example.com")` |
| `HostRegexp` | `regex` | 用[Go正则][re]匹配主机名 | `HostRegexp("^api[0-9]+\\.example\\.com$")` |
| `Path` | `pattern` | 精确匹配请求路径 | `Path("/api/v1/users")` |
| `PathPrefix` | `prefix` | 匹配路径前缀 | `PathPrefix("/api/")` |
| `PathRegexp` | `regex` | 用[Go正则][re]匹配路径 | `PathRegexp("\\.(jpeg\\|jpg\\|png)$")` |
| `Method` | `method` | 匹配HTTP方法 | `Method("POST")` |
| `Header` | `key` | 匹配请求头 `key` 是否存在 | `Header("Content-Type")` |
| `Header` | `key, value` | 精确匹配请求头 `key` 的值 | `Header("Content-Type", "application/json")` |
| `Header` | `key, op, value` | 用[比较运算符](#_4)对比请求头 `key` 的数值 [^tag] | `Header("Content-Length", "gt", "1024")` |
| `HeaderRegexp` | `key, regex` | 用[Go正则][re]匹配请求头 `key` 的值 | `HeaderRegexp("Content-Type", "^application/(json\\|yaml)$")` |
| `Query` | `key` | 匹配查询参数 `key` 是否存在 | `Query("page")` |
| `Query` | `key, value` | 精确匹配查询参数 `key` 的值 | `Query("page", "1")` |
| `Query` | `key, op, value` | 用[比较运算符](#_4)对比查询参数 `key` 的数值 [^tag] | `Query("page", "gt", "2")` |
| `QueryRegexp` | `key, regex` | 用[Go正则][re]匹配查询参数 `key` 的值 | `QueryRegexp("q", ".*")` |
| `ClientIP` | `ip...` | 将客户端IP与一个或多个IP或CIDR范围匹配 | `ClientIP("10.0.0.0/8", "::1")` |
| `Network` | `net` | 匹配连接的网络类型 | `Network("tcp")` |
| `Proto` | `protocol` | 匹配检测到的应用层协议（需开启流量嗅探） | `Proto("http")` |
| `BodyRegexp` | `regex` | 用[Go正则][re]匹配缓冲的请求体前缀 [^body] | `BodyRegexp("\"model\"\\s*:\\s*\"claude-opus[^\"]*\"")` |
| `BodyJSON` | `path, regex` | 用[GJSON路径](https://github.com/tidwall/gjson#path-syntax)提取JSON字段并以[Go正则][re]匹配 [^body] | `BodyJSON("model", "claude.*")` |
| `BodyJSON` | `path, op, value` | 用[GJSON路径](https://github.com/tidwall/gjson#path-syntax)提取数值JSON字段并以[比较运算符](#_4)对比 [^body] [^tag] | `BodyJSON("age", "ge", "18")` |
| `Admission` | `name` | 委托给命名的准入控制器 [^tag2] | `Admission("block-internal")` |
| `Bypass` | `name` | 委托给命名的分流规则 [^tag2] | `Bypass("china-mainland")` |

[^tag]: :material-tag: 3.3.0
[^tag2]: :material-tag: 3.2.4
[^body]: 请求体匹配器需要在处理器上开启 `sniffing: true`。仅读取请求体前缀用于匹配（见[请求体大小](#_6)），完整请求体原样转发。前缀会根据 `Content-Encoding`（`gzip`、`deflate`、`br`、`zstd`）自动解压后再匹配。
[re]: https://golang.org/pkg/regexp/

<span id="_4"></span>

#### 比较运算符

:material-tag: 3.3.0

`Header`、`Query`、`BodyJSON` 支持三参数形式配合比较运算符：
`Header("Content-Length", "gt", "1024")`。

| 运算符 | 匹配条件 |
|--------|---------|
| `gt` | 值大于 |
| `ge` | 值大于等于 |
| `lt` | 值小于 |
| `le` | 值小于等于 |
| `eq` | 值等于 |
| `ne` | 值不等于 |

值会解析为浮点数。非数值参数将静默跳过（视为不匹配）。对于多值请求头和查询参数，只要**任一**值满足比较即匹配成功。

### 优先级

`priority` (int, 默认: auto)
:    为避免路径重叠，节点默认按规则长度降序排序。优先级直接等于规则的长度——最长的规则
     拥有最高的优先级。

     设置 `priority` 为特定值可覆盖此行为。设置为**负数**则完全禁用自动优先级排序——所有匹配节点平等地通过选择器。

### 请求体大小

`bodySize` (int, 默认: 1MB)
:    用于请求体匹配器的HTTP请求体前缀最大读取大小（字节）。默认为 `1MB`（`1048576`）。
     上限为 `10MB`（`10485760`），超过部分会被截断。

     设置为 `-1` 可完全禁用请求体匹配。

     !!! note
         请求体前缀会根据 `Content-Encoding`（`gzip`、`deflate`、`br`、`zstd`）自动解压后再匹配。
         仅匹配用的前缀会被解码；转发到目标的完整请求体保持原始压缩状态。

### 正则语法

接受正则的匹配器使用 [Go的`regexp`语法](https://golang.org/pkg/regexp/)（RE2）。
不支持 Perl 风格的先行/后行断言和反向引用。

## 示例

### 基础：按主机名路由

```yaml
matcher:
  rule: Host("api.example.com")
```

### 布尔逻辑组合

```yaml
matcher:
  rule: 'Method("POST") && PathPrefix("/v1/") && Header("Content-Type", "application/json")'
```

### 请求体匹配

```yaml
matcher:
  rule: 'BodyJSON("output_config.effort", "^(xhigh|max)$")'
  bodySize: 65536
```

### 转发链组：按目标主机名路由

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

### 跳跃点组：按路径前缀路由

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

## 参见

- [参考：节点匹配器字段](../reference/configuration/file.md#node-matcher) — 节点上 `matcher` 的YAML字段参考
- [选择器](selector.md) — 匹配器过滤后的节点/条目选择方式
- [转发器](forwarder.md) — 基于匹配器路由的跳跃点组
- [转发链](chain.md) — 基于匹配器路由的转发链组
