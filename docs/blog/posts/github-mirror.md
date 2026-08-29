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

# 基于GOST反向代理实现网站镜像

在某些网络环境下，访问部分网站并不稳定。搭建一个"镜像站"是常见的解决思路：把目标站点原样搬到自己的域名或服务器上，让访问它的用户无感地拿到同样的内容。

但"镜像一个网站"远不止把首页 HTML 转发过来这么简单。一个现代网站（以 GitHub 为例）的资源分散在多个域名上（`github.com`、`raw.githubusercontent.com`、`avatars.githubusercontent.com`、`github.githubassets.com`……），页面里的链接、跳转、Cookie、安全策略全都写死了原始域名。如果只是简单转发，用户一点链接就又跳回了原站，图片资源也从原域加载，镜像就形同虚设。

这篇文章用 GitHub 为例，详细讲解如何用 GOST 的[反向代理](https://latest.gost.run/tutorials/reverse-proxy)能力，把一个多域名网站做成一个真正的镜像站。

<!-- more -->

## 核心思路：把"回程路由"编码进 URL

镜像站要解决的最核心问题只有一个：**当用户点开镜像里的某个链接时，GOST 怎么知道这个链接原来指向哪个上游域名？**

答案是把上游域名**编码进镜像 URL 里**：

```
原始 URL:  https://github.com/go-gost/gost
镜像 URL:  http://127.0.0.1:8000/github.com/go-gost/gost
                      ↑                    ↑
                  镜像地址            第一段路径 = 上游域名
```

把 `github.com` 作为 URL 的第一段路径。于是整个闭环就变成了一对互逆的变换：

| 方向 | 变换 | 机制 |
|------|------|------|
| 出程：上游 URL → 镜像 URL | `https://github.com/...` → `http://镜像/github.com/...` | 响应体 / `Location` 头的正则重写 |
| 回程：镜像 URL → 上游 URL | `http://镜像/github.com/...` → 请求 `github.com` 的 `/...` | `matcher.rule` 选节点 + `rewriteURL` 剥前缀 + `http.host` 还原 Host |

出程和回程各用一次正则，就能让镜像里的每个链接都能正确地再回到镜像，而不是跳回原站。

## 一个节点只能服务一个上游域名

这里有个必须先说清的约束：GOST 的节点是**一个地址 + 一个 SNI**。对 `github.com:443` 发起 TLS 连接时，SNI 和证书校验都钉死在这个地址上，Host 也由配置静态给定。这意味着**一个节点只能正确地服务一个上游域名**——不能把 `github.com` 和 `gist.github.com` 塞进同一个节点，因为连接 `gist.github.com` 时 SNI 必须是 `gist.github.com`，否则证书校验失败。

所以"镜像 GitHub"这件事，本质上是**每个上游域名一个节点**，节点之间用 `matcher.rule` 按第一段路径分流。好在这些域名在配置时都是静态已知的，不需要运行时动态解析。

> 唯一的例外是 `*.github.io`（GitHub Pages）：它由 **Host 头**路由而非 SNI 路由，所有子域共用一张 `*.github.io` 通配证书、解析到同一个 anycast 池。所以这类"Host 路由"的无限子域，可以用**一个节点 + `http.hostPattern`** 动态还原 Host 来服务，详见下文。

> 这也解释了为什么这里用**明文 host 前缀**（`/github.com/...`）而不是 base64 编码：GOST 的响应体重写是纯正则替换，正则算不出 base64。而 GitHub 这类站点的上游域名只有 `[a-z0-9-]+\.(github|githubusercontent|githubassets)\.com` 这一种形状，第一段路径绝对安全，明文还方便调试（curl 直接可读）。

## 三层改写

像 [LLM路由](llm-router.md)一样，镜像站要处理的改写也分三层，每一层对应 GOST 的一项能力。

### 1. 响应体的改写

页面 HTML 里塞满了指向原域的链接。通过[响应体的改写](https://latest.gost.run/tutorials/reverse-proxy/#_12)把它们的 host 换成镜像地址即可：

```yaml
rewriteResponseBody:
  - type: text/html,application/json
    match: 'https://(github\.com|raw\.githubusercontent\.com|...)'
    replacement: 'http://127.0.0.1:8000/$1'
    maxChunkSize: 8388608
```

`$1` 捕获整个 host，替换后原 host 自然变成了镜像 URL 的第一段路径，与回程路由的约定完全一致。

### 2. 响应头的改写

响应头里藏着一类"暗地里的原域引用"，比 body 里的链接更隐蔽：

* **`Location`**——302/301 跳转。`github.com` 的很多请求会跳回原域，必须把跳转目标也编码成镜像 URL，否则一次跳转就离开了镜像。
* **`Set-Cookie` 的 `Domain`**——登录态的 Cookie 绑定了原域。匿名浏览下若不去掉 `Domain`，剥掉域后 Cookie 会跟着路径泄漏到其它上游。
* **`Content-Security-Policy` / `Strict-Transport-Security`**——CSP 会阻断镜像域的资源加载，HSTS 会强制 HTTPS。镜像走 HTTP，这两类头必须删掉。

这些是 GOST 的头重写能力（`rewriteResponseHeader`），按"头名正则 + 值正则替换"工作：

```yaml
rewriteResponseHeader:
  - name: '(?i)^location$'
    match: 'https://github\.com'
    replacement: 'http://127.0.0.1:8000/github.com'
  - name: '(?i)^set-cookie$'
    match: '(?i)domain=\.?github\.com;?\s*'
    replacement: ''          # 值被删空 → 该头被删除
  - name: '(?i)^content-security-policy(-report-only)?$'
    match: '.*'
    replacement: ''
  - name: '(?i)^strict-transport-security$'
    match: '.*'
    replacement: ''
```

### 3. 请求头的改写（删除而非编码）

请求头方向与响应相反——浏览器访问镜像时，发出去的 `Referer`/`Origin` **已经是镜像地址**（`http://127.0.0.1:8000/...`）。它们不能再被"正向编码"，否则会把镜像地址泄漏给上游。正确做法是**删除**：

```yaml
rewriteRequestHeader:
  - name: '(?i)^(referer|origin|x-forwarded-host)$'
    match: '.*'
    replacement: ''
```

GitHub 浏览场景的 CSRF 防护靠的是表单 token 而非 `Referer`，所以删除既最简单又最安全。

### 4. 例外：`*.github.io` 的动态 Host

前面说"一个节点一个上游域名"，因为 SNI 是静态的。但 `*.github.io`（GitHub Pages）不一样：Fastly 按 **Host 头**路由内容，而不是按 SNI。实测确认——

* 所有 `*.github.io` 都解析到同一个 anycast 池（`185.199.108~111.153`）；
* 共用的是一张 `*.github.io` 通配证书，SNI 换成任意子域都能通过校验；
* 同一 IP 下，`Host: microsoft.github.io` 返回微软的页、`Host: google.github.io` 返回 Google 的页——**内容由 Host 头决定**。

于是这类无限子域不需要"每个子域一个节点"，只需要一个节点，用 `http.hostPattern` 把 Host 从路径里动态提取出来：

```yaml
- name: githubio
  matcher:
    rule: PathRegexp(`^/[a-z0-9-]+\.github\.io/`)
  addr: github.io:443
  tls: { secure: true, serverName: github.io }   # SNI 静态，通配证书兜底
  http:
    hostPattern: '^/([a-z0-9-]+\.github\.io)/'    # 从路径提取 host
    host: '$1'                                    # Host = 第一个捕获组
    rewriteURL:
      - { match: '^/[a-z0-9-]+\.github\.io/', replacement: '/' }   # 剥掉 host 前缀
    rewriteRequestHeader:
      - { name: '(?i)^cookie$', match: '.*', replacement: '' }
```

`hostPattern` 是作用于 URL 路径的正则；命中时把 `http.host` 当模板，展开 `$1`/`$2` 捕获组。它**只改 Host 头**，不改拨号目标和 SNI（那两者仍是静态的），所以恰好适配"Host 路由"的上游——这也是它和普通节点唯一的能力差异。

## 完整配置示例

下面是基于 [GOST v3](https://latest.gost.run/) 的 GitHub 匿名只读镜像，客户端通过 HTTP 访问 GOST（`127.0.0.1:8000`），GOST 对上游走 HTTPS 并校验证书——**全程无需 MITM，无需客户端信任任何证书**。

```yaml
# gost.yaml
# 所有镜像域名的合集，用 YAML 锚点收敛成单一来源。
# 新增一个上游域名时：在这里加一条 + 加一个节点。
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
        # 兜底：裸首页 GET /，以及任何不带 origin 前缀的路径
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

        # 主站
        - name: github
          matcher:
            rule: PathPrefix(`/github.com/`) || PathPrefix(`/www.github.com/`)
          addr: github.com:443
          tls: { secure: true, serverName: github.com }
          http:
            host: github.com
            rewriteURL:
              - { match: '^/github\.com/', replacement: '/' }   # 剥掉第一段
            rewriteResponseBody:
              - { type: 'text/html,application/json', match: *origins, replacement: 'http://127.0.0.1:8000/$1', maxChunkSize: 8388608 }
            rewriteRequestHeader:
              - { name: '(?i)^(referer|origin|x-forwarded-host)$', match: '.*', replacement: '' }
            rewriteResponseHeader:
              - { name: '(?i)^location$', match: *origins, replacement: 'http://127.0.0.1:8000/$1' }
              - { name: '(?i)^set-cookie$', match: '(?i)domain=\.?github\.com;?\s*', replacement: '' }
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }
              - { name: '(?i)^strict-transport-security$', match: '.*', replacement: '' }

        # Gist 代码片段
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

        # REST API（JSON）
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

        # 静态资源（CSS/JS）
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

        # 原始文件内容
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
              - { name: '(?i)^cookie$', match: '.*', replacement: '' }  # 防跨域 Cookie 泄漏
            rewriteResponseHeader:
              - { name: '(?i)^location$', match: *origins, replacement: 'http://127.0.0.1:8000/$1' }
              - { name: '(?i)^content-security-policy(-report-only)?$', match: '.*', replacement: '' }

        # 头像
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

        # Release 附件下载
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

        # 仓库归档下载：github.com/<o>/<r>/archive/... 302 到这里
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

        # README/issues 里被代理的外链图片
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

        # issues/PR/README 里用户上传的图片（旧版上传域）
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

        # 社交分享预览 / og:image 卡片
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

        # GitHub Pages (*.github.io)：Host 路由而非 SNI 路由，一个节点服务所有子域
        - name: githubio
          matcher:
            rule: PathRegexp(`^/[a-z0-9-]+\.github\.io/`)
          addr: github.io:443
          tls: { secure: true, serverName: github.io }
          http:
            hostPattern: '^/([a-z0-9-]+\.github\.io)/'   # 从路径提取 host
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

启动：

```bash
./gost -C gost.yaml
```

## 数据流

一次访问仓库页面的完整往返：

```
GET http://127.0.0.1:8000/github.com/go-gost/gost
  → Sniffer 嗅探 HTTP，PathPrefix(`/github.com/`) 选中 github 节点
  → rewriteURL 剥前缀: /github.com/go-gost/gost → /go-gost/gost
  → http.host 还原: Host = github.com
  → rewriteRequestHeader 删除 Referer/Origin
  → 转发至 https://github.com/go-gost/gost

响应（200 text/html）
  → rewriteResponseBody: https://github.com/... → http://127.0.0.1:8000/github.com/...
  → rewriteResponseHeader:
      Location    → 编码为镜像 URL
      Set-Cookie  → 剥离 Domain=github.com
      CSP / HSTS  → 删除
  → 返回客户端

客户端点击某个图片链接 http://127.0.0.1:8000/avatars.githubusercontent.com/u/28017
  → PathPrefix(`/avatars.githubusercontent.com/`) 选中 avatars 节点
  → 剥前缀 + 还原 Host → 转发至 https://avatars.githubusercontent.com/u/28017

客户端访问某个 Pages 站点 http://127.0.0.1:8000/microsoft.github.io/
  → PathRegexp(`^/[a-z0-9-]+\.github\.io/`) 选中 githubio 节点
  → hostPattern 提取 Host = microsoft.github.io（SNI 仍是静态 github.io）
  → rewriteURL 剥前缀: /microsoft.github.io/ → /
  → 转发至 https://github.io/，Host: microsoft.github.io
```

## 缓存

镜像站的每一次请求都要回源 GitHub，页面又大、资源又多，反复回源既慢又费。GOST 的 [HTTP响应缓存](https://latest.gost.run/tutorials/http-cache/)可以给镜像再套一层，命中的请求直接本地返回，不再打上游。

关键在于一个看似矛盾的点：GitHub 对页面响应发的是 `Cache-Control: max-age=0, private`，**默认按这个头缓存的话什么也缓存不了**。但对匿名只读镜像来说这恰恰是安全的——所有用户看到的是同一份公开内容，没有因人而异的私有数据，跨用户命中不会泄漏任何东西。所以这里显式无视上游的 `Cache-Control`，改用自定 TTL。

只需在上面的完整配置上做三处增改：

```yaml
services:
  - name: github-mirror
    addr: :8000
    cache: mirror-cache        # ① service 级：引用一个命名缓存存储
    handler:
      type: tcp
      metadata:
        sniffing: true
        # ② 缓存策略（handler 元数据）
        cache.ttl: 10m          # 默认 TTL（无 status 覆盖时）
        cache.status.200: 30m   # 200（页面/JSON/资源）存更久
        cache.serveStale: true  # 回源失败时，返回过期缓存兜底
        cache.maxBodyBytes: 8388608  # 8MB 上限，更大的 raw/release 文件不缓存

# ③ 命名缓存存储：内存后端 + LRU 淘汰
caches:
  - name: mirror-cache
    memory:
      maxBytes: 268435456   # 总字节上限 256MB，超出按 LRU 淘汰
      eviction: lru
```

* `cache.ttl` / `cache.status.<code>` 控制各类响应的存活时间；匿名的公开内容，把页面存 30 分钟通常没有副作用。
* `cache.serveStale` 在 GitHub 不可达时用过期缓存兜底——对"镜像"这个场景尤其有用，源站抖动的瞬间用户仍能读到内容。
* `cache.maxBodyBytes` 是缓存单条响应的体积上限，超过直接透传不缓存，避免把大文件塞进内存。

> 缓存的键按请求的 Method + Host + RequestURI 计算。由于回程路由把上游域名编码进了路径，不同上游域名的同名请求天然不会互相串键。

## 边界

这套方案解决的是**匿名只读浏览**——公开仓库、README、头像、Raw 文件、归档下载。以下场景不在范围内，也没有刻意去兼容：

* **登录态**——登录链路有多个硬断点：CAPTCHA 的第三方 iframe、WebAuthn 的 `rpId` 绑定原域、Secure Cookie 要求 HTTPS，镜像走 HTTP 无法闭环。
* **JS 运行时注入的 URL**——运行时由脚本拼接的地址无法通过静态重写覆盖，需要更重的方案。
* **`docs.github.com` 等独立站点**——它自己又有一堆资源域，部分镜像比不镜像更糟，索性不纳入。

镜像站的价值在于"能逛、能读、能下载"，而不是完整复刻一个有登录态的 SaaS。把握住这个边界，用最少的机制覆盖最多的内容，正是反向代理式镜像的优雅之处。
