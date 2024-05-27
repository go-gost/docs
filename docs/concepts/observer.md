---
comments: true
---

# 观测器

观测器是一个用来观测服务内部状态的组件，包括服务状态的变化，连接和流量统计信息，观测器通过事件的方式上报这些信息。

!!! tip "动态配置"
    观测器支持通过[Web API](/tutorials/api/overview/)进行动态配置。

!!! note "使用限制"
    观测器目前仅能以插件的方式来使用。

## 插件

观测器可以配置为使用外部[插件](/concepts/plugin/)服务。

```yaml
observers:
- name: observer-0
  plugin:
    type: grpc
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

`addr` (string, required)
:    插件服务地址

`tls` (duration, default=null)
:    设置后将使用TLS加密传输，默认不使用TLS加密。

## 使用观测器

当服务的状态变化时会通过服务上的观测器上报状态，如果服务开启了统计(`enableStats`选项)，同时也会上报连接和流量统计信息。

```yaml hl_lines="4 10"
services:
- name: service-0
  addr: ":8080"
  observer: observer-0 # 服务上的观测器
  handler:
    type: http
  listener:
    type: tcp
  metadata:
    enableStats: true # 开启统计

observers:
- name: observer-0
  plugin:
    type: grpc
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

## HTTP插件

```yaml
observers:
- name: observer-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/observer
```

### 请求示例

**上报服务状态**

```bash
curl -XPOST http://127.0.0.1:8000/observer \
-d '{"events":[
{"kind":"service","service":"service-0","type":"status", 
"status":{"state":"running","msg":"service service-0 is running"}} 
]}'
```

`kind` (string)
:    事件种类：`service` - 服务级别事件, `handler` - 处理器级别事件

`service` (string)
:    服务名

`type` (string)
:    事件类型：`status` - 服务状态，`stats` - 统计信息

`status.state` (string)
:    服务状态：`running` - 服务创建并运行，`ready` - 服务已就绪，`failed` - 服务运行失败，`closed` - 服务已关闭

`status.msg` (string)
:    服务状态说明

**上报统计信息**

单个服务会周期性(5秒)通过观测器上报统计信息，当服务的统计信息无更新时(无任何连接或流量变化)停止上报。

```bash
curl -XPOST http://127.0.0.1:8000/observer \
-d '{"events":[
{"kind":"service","service":"service-0","type":"stats", 
"stats":{"totalConns":1,"currentConns":0,"inputBytes":235,"outputBytes":632,"totalErrs":0}}
]}'
```

`stats.totalConns` (uint64)
:    服务处理的总连接数

`stats.currentConns` (uint64)
:    服务当前未完成的连接数

`stats.inputBytes` (uint64)
:    服务接收的数据总字节数

`stats.outputBytes` (uint64)
:    服务发送的数据总字节数

`stats.totalErrs` (uint64)
:    服务处理请求的总错误数


## 处理器(Handler)上的观测器

对于支持认证的代理服务(HTTP，HTTP2，SOCKS4，SOCKS5，Relay)，观测器也可以用在处理器上。

```yaml hl_lines="6"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    observer: observer-0
  listener:
    type: tcp

observers:
- name: observer-0
  plugin:
    addr: 127.0.0.1:8000
```

### 基于用户标识的流量统计

服务级别的观测器只能用来观测服务整体的统计信息，无法针对用户进行更细的划分。如果需要实现此功能需要组合使用认证器插件和处理器上的观测器插件。
    
认证器插件在认证成功后返回用户标识，GOST会将此用户标识信息再次传递给观测器插件服务。

```bash
curl -XPOST http://127.0.0.1:8000/observer \
-d '{"events":[
{"kind":"handler","service":"service-0","client":"user1","type":"stats",
"stats":{"totalConns":1,"currentConns":0,"inputBytes":78,"outputBytes":574,"totalErrs":0}},
{"kind":"handler","service":"service-0","client":"user2","type":"stats",
"stats":{"totalConns":1,"currentConns":0,"inputBytes":78,"outputBytes":574,"totalErrs":0}}
]}'
```

`client` (string)
:    用户标识