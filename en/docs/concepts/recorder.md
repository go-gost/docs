---
comments: true
---

# Data Recording

## Recorder

!!! tip "Dynamic configuration"
    Recorder supports dynamic configuration via [Web API](../tutorials/api/overview.md).

Recorder can be used to record specific data, by configuring and referencing different recorder types to record data to different targets.

```yaml
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

## Recorder Types

Currently supported recorder types are: file, TCP servie, HTTP service, redis.

### File

File recorder records data to the specified file.

```yaml
recorders:
- name: recorder-0
  file:
    path: /path/to/recorder/file
    sep: "\n"
```

`file.path` (string)
:    file path

`sep` (string)
:    Record separator. If set, this separator will be inserted between two records

### TCP Service

TCP recorder sends data to the specified TCP service.

```yaml
recorders:
- name: recorder-0
  tcp:
    addr: 192.168.1.1:1234
    timeout: 10s
```

`tcp.addr` (string)
:    TCP service address

`timeout` (duration)
:    Timeout for establishing a connection

### HTTP Service

HTTP recorder sends data to the specified HTTP service using the HTTP `POST` method. If HTTP returns status code `200`, the recording is considered successful.

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
:    HTTP URL address

`timeout` (duration)
:    Timeout for establishing a connection

`http.header` (object)
:    HTTP request header.

### Redis

Redis recorder records data to the redis server.

```yaml
recorders:
- name: recorder-0
  redis:
    addr: 127.0.0.1:6379
    db: 1
    username: user
    password: 123456
    key: gost:recorder:recorder-0
    type: set
```

`addr` (string, required)
:    redis server address

`db` (int, default=0)
:    database name 

`username` (string)
:    username

`password` (string)
:    password

`key` (string, required)
:    redis key

`type` (string, default=set)
:    data type: Set(`set`), Sorted Set(`sset`), List(`list`).

## Recorder Usage

The list of recorders to use is specified via `service.recorders`.

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
:    recorder name.

`record` (string, required)
:    record object.

`metadata` (object)
:    options.

`http.body` (bool, default=false)
:    when recording HTTP data, both the request and the response body are recorded.

`http.maxBodySize` (int, default=1048576)
:    HTTP request and response body data record size, default is 1MB, only valid when `http.body` option is enabled.

### Record Object

Currently supported record objects are:

#### recorder.service.client.address

All client addresses accessing the service

#### recorder.service.router.dial.address

All visited destination addresses

#### recorder.service.router.dial.address.error

All destination addresses that failed to establish a connection

#### recorder.service.handler

The handler records the information of each request in JSON format

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

For handlers that can handle HTTP traffic, HTTP request and response will be additionally recorded in the `http` field

```json
{"service":"service-0","network":"tcp",
"remote":"[::1]:59234","local":"[::1]:8080",
"host":"www.example.com","client":"user1",
"http":{"host":"www.example.com","method":"GET","proto":"HTTP/1.1","scheme":"http","uri":"http://www.example.com/","statusCode":200,
"request":{"contentLength":0,"header":{"Accept":["*/*"],"Proxy-Authorization":["Basic dXNlcjE6cGFzczE="],"Proxy-Connection":["Keep-Alive"],"User-Agent":["curl/8.5.0"]}},
"response":{"contentLength":1256,"header":{"Age":["525134"],"Cache-Control":["max-age=604800"],"Content-Length":["1256"],"Content-Type":["text/html; charset=UTF-8"],"Date":["Sat, 14 Sep 2024 01:56:59 GMT"],"Etag":["\"3147526947+ident\""],"Expires":["Sat, 21 Sep 2024 01:56:59 GMT"],"Last-Modified":["Thu, 17 Oct 2019 07:18:26 GMT"],"Server":["ECAcc (sac/2538)"],"Vary":["Accept-Encoding"],"X-Cache":["HIT"]}}},
"time":"2024-09-14T09:56:58.997252296+08:00",
"duration":282125918,
"sid":"crk3evaohhhk8lipb8qg"
}
```

For handlers that can handle TLS traffic, TLS handshake will be additionally recorded in the `tls` field

```json
{"service":"service-0","network":"tcp",
"remote":"127.0.0.1:50144","local":"127.0.0.1:443",
"host":"www.google.com:443","clientIP":"127.0.0.1",
"tls":{"serverName":"www.google.com","cipherSuite":"TLS_AES_256_GCM_SHA384","compressionMethod":0,"proto":"h2","version":"tls.1.3"},
"duration":2091323186,
"time":"2024-09-16T16:53:19.235320555+08:00",
"sid":"crmjfvqohhhgqqu0f0h0"
}
```

The DNS handler will record DNS request and response information in the `dns` field

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
}
```

#### recorder.service.handler.serial

Serial port device [communication data](https://gost.run/en/tutorials/serial/#data-record)

## Plugin

Recorder can be configured to use an external [plugin](plugin.md) service, and authenticator will forward the request to the plugin server for processing. Other parameters are invalid when using plugin.

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
:    plugin type: `grpc`, `http`.

`addr` (string, required)
:    plugin server address.

`tls` (object, default=null)
:    TLS encryption will be used for transmission, TLS encryption is not used by default.

### HTTP Plugin

```yaml
recorders:
- name: recorder-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/recorder
```

#### Example

```bash
curl -XPOST http://127.0.0.1:8000/recorder -d '{"data":"aGVsbG8gd29ybGQ="}'
```

```json
{"ok":true}
```