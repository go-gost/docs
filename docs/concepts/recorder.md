---
comments: true
---

# 数据记录

## 记录器

!!! tip "动态配置"
    记录器支持通过[Web API](/tutorials/api/overview/)进行动态配置。

记录器可以用来记录特定数据，通过配置和引用不同的记录器类型将数据记录到不同的目标中。

```yaml hl_lines="4 5 6 12"
services:
- name: service-0
  addr: :8080
  recorders:
  - name: recorder-0
    record: recorder.service.handler
  handler:
    type: auto
  listener:
    type: tcp
recorders:
- name: recorder-0
  file:
    path: /path/to/recorder/file
    sep: "\n"
```

## 记录器类型

目前支持的记录器类型有：文件，TCP服务，HTTP服务，redis。

### 文件

文件记录器将数据记录到指定文件。

```yaml
recorders:
- name: recorder-0
  file:
    path: /path/to/recorder/file
    sep: "\n"
```

`file.path` (string)
:    文件路径

`sep` (string)
:    记录分割符，如果设置则会在两条记录中间插入此分割符

### TCP服务

TCP服务记录器将数据发送到指定的TCP服务。

```yaml
recorders:
- name: recorder-0
  tcp:
    addr: 192.168.1.1:1234
    timeout: 10s
```

`tcp.addr` (string)
:    TCP服务地址

`timeout` (duration)
:    TCP服务建立连接超时时长


### HTTP服务

记录器将数据以HTTP `POST`方法送到指定的HTTP服务。HTTP返回状态码`200`则认为记录成功。

```yaml
recorders:
- name: recorder-0
  http:
    url: http://192.168.1.1:80
    timeout: 10s
    header:
      foo: bar
```

`http.url` (string)
:    HTTP URL地址。

`http.timeout` (duration)
:    请求超时时长。

`http.header` (object)
:    自定义HTTP请求头。

### Redis

Redis记录器将数据记录到redis服务中。

```yaml
recorders:
- name: recorder-0
  redis:
    addr: 127.0.0.1:6379
    db: 1
    password: 123456
    key: gost:recorder:recorder-0
    type: set
```

`addr` (string, required)
:    redis服务地址

`db` (int, default=0)
:    数据库名

`password` (string)
:    密码

`key` (string, required)
:    redis key

`type` (string, default=set)
:    数据类型，支持的类型有集合(`set`)，有序集合(`sset`)，列表(`list`)。

## 使用记录器

通过`service.recorders`指定所使用的记录器列表。

```yaml
services:
- name: service-0
  addr: :8080
  recorders:
  - name: recorder-0
    record: recorder.service.handler
    metadata:
      http.body: true
      http.maxBodySize: 1048576
  - name: recorder-1
    record: recorder.service.router.dial.address.error
  handler:
    type: auto
  listener:
    type: tcp
```

`name` (string, required)
:    记录器名，引用定义的记录器。

`record` (string, required)
:    记录对象。

`metadata` (object)
:    参数选项。

`http.body` (bool, default=false)
:    当记录HTTP数据时，同时记录请求和相应体。

`http.maxBodySize` (int, default=1048576)
:    HTTP请求和响应体数据记录大小，默认为1MB，仅当`http.body`选项开启后有效。

### 记录对象

目前支持的记录对象有：


#### recorder.service.client.address

所有访问服务的客户端地址

#### recorder.service.router.dial.address

所有访问的目标地址

#### recorder.service.router.dial.address.error

建立连接失败的目标地址

#### recorder.service.handler

处理器以JSON格式记录每次请求处理的相关信息

```json
{"service":"service-0","network":"tcp",
"remote":"[::1]:37808","local":"[::1]:8080",
"host":":18000",
"err":"dial tcp :18000: connect: connection refused",
"time":"2024-09-14T09:53:13.281723394+08:00",
"duration":1430855,
"sid":"crk2fcqohhhpjksr2sgg"
}
```

对于能够处理HTTP流量的处理器会在`http`字段中额外记录HTTP请求和响应信息

```json
{"service":"service-0","network":"tcp",
"remote":"[::1]:59234","local":"[::1]:8080",
"host":"www.example.com","client":"user1","clientIP":"192.168.1.2",
"http":{"host":"www.example.com","method":"GET","proto":"HTTP/1.1","scheme":"http","uri":"http://www.example.com/","statusCode":200,
"request":{"contentLength":0,"header":{"Accept":["*/*"],"Proxy-Authorization":["Basic dXNlcjE6cGFzczE="],"Proxy-Connection":["Keep-Alive"],"User-Agent":["curl/8.5.0"]}},
"response":{"contentLength":1256,"header":{"Age":["525134"],"Cache-Control":["max-age=604800"],"Content-Length":["1256"],"Content-Type":["text/html; charset=UTF-8"],"Date":["Sat, 14 Sep 2024 01:56:59 GMT"],"Etag":["\"3147526947+ident\""],"Expires":["Sat, 21 Sep 2024 01:56:59 GMT"],"Last-Modified":["Thu, 17 Oct 2019 07:18:26 GMT"],"Server":["ECAcc (sac/2538)"],"Vary":["Accept-Encoding"],"X-Cache":["HIT"]}}},
"time":"2024-09-14T09:56:58.997252296+08:00",
"duration":282125918,
"sid":"crk3evaohhhk8lipb8qg"
}
```

对于DNS处理器会在`dns`字段中记录DNS请求和响应信息

```json
{"service":"service-0","network":"udp",
"remote":"127.0.0.1:52801","local":":1053","host":"udp://192.168.1.1:53",
"dns":{"id":58727,"name":"www.google.com.","class":"IN","type":"A",
"question":";; opcode: QUERY, status: NOERROR, id: 58727\n;; flags: rd ad; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 1\n\n;; OPT PSEUDOSECTION:\n; EDNS: version 0; flags:; udp: 1232\n; COOKIE: e9fde848447e55b9\n\n;; QUESTION SECTION:\n;www.google.com.\tIN\t A\n",
"answer":";; opcode: QUERY, status: NOERROR, id: 58727\n;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0\n\n;; QUESTION SECTION:\n;www.google.com.\tIN\t A\n\n;; ANSWER SECTION:\nwww.google.com.\t227\tIN\tA\t157.240.17.35\n",
"cached":false},
"time":"2024-09-14T10:10:22.82722339+08:00",
"duration":2409303,
"sid":"crk2ig2ohhhpjksr2shg"
```

关于处理器上的记录器更详细的使用示例可以参考这篇[博文](https://gost.run/blog/2024/log/)

#### recorder.service.handler.serial

记录串口设备[通讯数据](https://gost.run/tutorials/serial/#_5)

## 插件

记录器可以配置为使用外部[插件](/concepts/plugin/)服务，记录器会将数据转发给插件服务处理。当使用插件时其他参数无效。

```yaml
recorders:
- name: recorder-0
  plugin:
    type: grpc
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

`type` (string, default=grpc)
:    插件类型：`grpc`, `http`。

`addr` (string, required)
:    插件服务地址。

`tls` (object, default=null)
:    设置后将使用TLS加密传输，默认不使用TLS加密。

### HTTP插件

```yaml
recorders:
- name: recorder-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/recorder
```

#### 请求示例

```bash
curl -XPOST http://127.0.0.1:8000/recorder -d '{"data":"aGVsbG8gd29ybGQ="}'
```

```json
{"ok":true}
```
