---
comments: true
---

# 节点存活探测

:material-tag: 3.3.0

GOST支持对转发链中的每个节点进行主动健康检查。当节点配置了`probe`后，GOST会启动后台goroutine周期性探测该节点的可达性和时延，自动将死亡节点从选择器中剔除，并在节点恢复后重新纳入。

相比于仅依赖连接失败来被动标记节点，主动探测有两大优势：

- **提前剔除**：节点在收到真实流量之前就被标记为死亡，避免请求失败。
- **时延感知**：配合`lowestlatency`策略，选择器可以始终选择时延最低的节点。

## 工作原理

```
每个带probe的节点 → 独立goroutine → 定时探测
    │
    ├─ 成功 → Marker().Reset() → 节点标记为健康 → FailFilter放行
    │
    └─ 失败 → Marker().Mark() → 节点标记为死亡 → FailFilter跳过
```

探测走节点自身的transport，直接`Dial(node.Addr)`接通节点后，按探测类型校验：

- **TCP**：Dial + Handshake成功即视为健康。
- **HTTP**：通过已建立的隧道连接发送HTTP GET请求，校验响应状态码。
- **Cmd**：运行Shell命令；退出码0=健康，非0=不健康。**不需要**transport或`addr`——命令在本地执行。

## 配置

在节点配置中添加`probe`块：

```yaml
chains:
- name: chain-1
  hops:
  - name: hop-1
    selector:
      strategy: round
      maxFails: 1
      failTimeout: 10s
    nodes:
    - name: proxy1
      addr: 10.0.0.1:1080
      connector:
        type: socks5
      dialer:
        type: tcp
      probe:
        type: tcp
        addr: 8.8.8.8:53
        interval: 30s
        timeout: 10s
    - name: proxy2
      addr: 10.0.0.2:1080
      connector:
        type: socks5
      dialer:
        type: tcp
      probe:
        type: http
        addr: httpbin.org:80
        httpPath: /get
        expectedStatus: 200
        interval: 60s
        timeout: 15s
    - name: proxy3
      addr: proxy3.local:1080
      connector:
        type: socks5
      dialer:
        type: tcp
      probe:
        type: cmd
        command: './scripts/health-check.sh'
        interval: 60s
        timeout: 10s
```

### 参数说明

`type` (string, default=tcp)
:    探测类型：`tcp`、`http` 或 `cmd`。

`addr` (string, tcp/http 必需)
:    探测目标地址。探测通过节点隧道到达此地址。`type: cmd` 时不需要。

`interval` (duration, default=30s)
:    探测间隔。首次探测在启动时立即执行。

`timeout` (duration, default=10s)
:    单次探测超时时间。

`httpPath` (string, default=/)
:    HTTP探测的请求路径。仅`type: http`时有效。

`httpHost` (string)
:    HTTP请求的Host头。默认使用`addr`的值。

`httpHeaders` (map[string]string)
:    HTTP探测的附加请求头。

`expectedStatus` (int, default=200)
:    期望的HTTP响应状态码。仅`type: http`时有效。

`command` (string, cmd 必需)
:    要执行的Shell命令。在Unix上通过 `sh -c <command>` 运行，在Windows上通过 `cmd /C <command>` 运行。退出码0=健康，非0(或超时)=不健康。不使用节点transport——命令直接在GOST主机上执行。

!!! note "探测目标"
    探测目标(`addr`)是**穿透节点后**访问的地址。例如`addr: 8.8.8.8:53`表示通过节点proxy1的SOCKS5隧道连接到`8.8.8.8:53`。如果只想验证节点本身可达，将`addr`设置为节点的`addr`即可。

## 选择器策略

主动探测与选择器策略配合使用，可以实现基于健康状态的智能路由。

### FailFilter

所有选择器策略都默认配置了`FailFilter`。被探测标记为死亡的节点会被自动跳过：

```yaml
selector:
  strategy: round          # 任意策略均可
  maxFails: 1              # 标记几次后剔除
  failTimeout: 10s         # 标记有效时长
```

节点恢复后(探测成功 → `Marker().Reset()`)，`FailFilter`会将其重新纳入候选池。

### lowestlatency 策略

按探测时延选择节点，总是选时延最低的：

```yaml
selector:
  strategy: lowestlatency
  maxFails: 1
  failTimeout: 10s
```

!!! note "无探测结果的节点"
    未配置`probe`的节点没有时延数据，`lowestlatency`策略会将它们排在最后作为兜底。已配置`probe`但探测失败的节点同样被降级。

### maxLatency 过滤器

过滤掉时延超过阈值的节点：

```yaml
selector:
  strategy: round
  maxFails: 1
  failTimeout: 10s
  maxLatency: 500ms          # 时延超过500ms的节点被过滤
```

没有探测结果的节点不受影响(保守放行)。

## 生命周期

节点探测的goroutine生命周期与节点绑定：

- **启动**：配置解析(`ParseNode`)时，由hot-reload和初始加载共同触发。
- **停止**：节点`Close()`或整链`Unregister`时自动取消。配置热重载时会先停旧链再启新链，无goroutine泄漏。

## 示例

### TCP探测 + FailFilter

两个节点，一个存活一个死亡。探测提前标记死亡节点，所有请求都成功：

```yaml
services:
- name: proxy
  addr: :8080
  handler:
    type: http
    chain: my-chain
  listener:
    type: tcp

- name: relay
  addr: 127.0.0.1:18081
  handler:
    type: http
  listener:
    type: tcp

chains:
- name: my-chain
  hops:
  - name: hop-1
    selector:
      strategy: round
      maxFails: 1
      failTimeout: 10s
    nodes:
    - name: node-live
      addr: 127.0.0.1:18081
      connector:
        type: http
      probe:
        type: tcp
        addr: 127.0.0.1:18081
        interval: 5s
    - name: node-dead
      addr: 127.0.0.1:18082   # 此端口未监听
      connector:
        type: http
      probe:
        type: tcp
        addr: 127.0.0.1:18082
        interval: 5s
```

### lowestlatency 时延选择

两个存活节点，自动选时延最低的：

```yaml
chains:
- name: my-chain
  hops:
  - name: hop-1
    selector:
      strategy: lowestlatency
      maxFails: 1
      failTimeout: 10s
    nodes:
    - name: node-a
      addr: 127.0.0.1:18081
      connector:
        type: http
      probe:
        type: tcp
        addr: 127.0.0.1:18081
        interval: 5s
    - name: node-b
      addr: 127.0.0.1:18082
      connector:
        type: http
      probe:
        type: tcp
        addr: 127.0.0.1:18082
        interval: 5s
```

### HTTP探测

通过节点隧道发送HTTP GET请求并校验状态码：

```yaml
nodes:
- name: web-proxy
  addr: 10.0.0.1:3128
  connector:
    type: http
  probe:
    type: http
    addr: httpbin.org:80
    httpPath: /status/200
    httpHost: httpbin.org
    expectedStatus: 200
    interval: 30s
    timeout: 10s
```

### Cmd探测

在GOST主机上运行Shell命令来外部判断节点健康状态。绕过节点transport——适用于基于时间的路由、外部健康检查脚本或网络无法探测的场景：

```yaml
nodes:
- name: biz-hours-only
  addr: 8.8.8.8:1080
  connector:
    type: socks5
  probe:
    type: cmd
    command: 'test $(date +%H) -ge 9 -a $(date +%H) -lt 18'
    interval: 30s
    timeout: 5s
- name: with-check
  addr: 8.8.8.8:1080
  connector:
    type: socks5
  probe:
    type: cmd
    command: './scripts/health-check.sh'
    interval: 60s
    timeout: 10s
```

注意Cmd探测**不需要**配置`addr`——命令在本地执行，不通过节点隧道。

## 限制

- **首跳节点**：当前实现对首跳/单跳节点(客户端可直接拨达)准确有效。深跳节点(需经上游hop才能到达)的探测暂不支持。
- **Cmd探测**以与GOST进程相同的用户身份运行命令。配置文件本身是可信输入，请勿加载不受信任的配置。
