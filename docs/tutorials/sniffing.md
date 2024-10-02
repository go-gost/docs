---
comments: true
---

默认情况下客户端与服务端之间的数据交互对于中间的代理和转发服务来说是透明的，除了部分服务（例如SNI代理，透明代理等）需要根据请求中的信息获取目标主机地址外，都是对所经过的流量进行简单的转发而并不知道所转发的数据内容。

有些时候我们可能需要对流量进行更进一步的分析，从而可以实现流量的实时监控，统计分析，对于开发人员来说也可以更好的辅助协议调试。

# 流量嗅探

!!! note "协议支持"
    流量嗅探目前支持HTTP/1，HTTP/2，TLS协议和DNS协议。

流量嗅探是指对于所中转的流量进行分析，一般是对客户端的首次请求数据进行协议匹配，大多数情况下会检查是否为HTTP或TLS请求。如果满足条件，后面的数据交互就会按照特定的协议进行解析，从而可以获取到具体的通信内容。

GOST中大部分的代理和转发服务都支持流量嗅探（具体请查看响应的协议文档说明）。流量嗅探需要配合[记录器](../concepts/recorder.md)插件，服务会将嗅探到的内容通过记录器实时上报。 

例如以下是一个开启了流量嗅探的HTTP代理服务，当代理协商阶段结束后，会进一步检查流量，尝试嗅探出HTTP或TLS流量。

```yaml hl_lines="8-11 15-18"
services:
  - name: service-0
    addr: :8080
    recorders:
      - name: recorder-0
        record: recorder.service.handler
        metadata:
          # 同时记录HTTP请求和响应体
          http.body: true
          # 记录的请求和响应体最大大小，默认最多记录1MB数据。
          http.maxBodySize: 1048576
    handler:
      type: http
      metadata:
        # 开启流量嗅探
        sniffing: true
        # 流量嗅探超时时长，当嗅探请求超时后，退回到简单的数据中转逻辑。
        sniffing.timeout: 3s
    listener:
      type: tcp
recorders:
  - name: recorder-0
    http:
      url: http://localhost:8000
      timeout: 1s
```

当通过代理请求`http://www.example.com`时，代理会嗅探到HTTP协议，并在请求结束后上报HTTP请求响应信息：

```bash
curl -p -x localhost:8080 http://www.example.com
```

```json
{"service":"service-0","network":"tcp","remote":"[::1]:46944","local":"[::1]:8080",
"host":"www.example.com:80","proto":"http","clientIP":"::1",
"http":{"host":"www.example.com","method":"GET","proto":"HTTP/1.1","scheme":"","uri":"/","statusCode":200,
"request":{"contentLength":0,"header":{"Accept":["*/*"],"User-Agent":["curl/8.5.0"]},"body":null},
"response":{"contentLength":1256,"header":{"Accept-Ranges":["bytes"],"Age":["531603"],"Cache-Control":["max-age=604800"],"Content-Length":["1256"],"Content-Type":["text/html; charset=UTF-8"],"Date":["Wed, 02 Oct 2024 09:13:54 GMT"],"Etag":["\"3147526947+gzip\""],"Expires":["Wed, 09 Oct 2024 09:13:54 GMT"],"Last-Modified":["Thu, 17 Oct 2019 07:18:26 GMT"],"Server":["ECAcc (sac/255D)"],"Vary":["Accept-Encoding"],"X-Cache":["HIT"]},
"body":"PCFkb2N0eXBlIGh0bWw+CjxodG1sPgo8aGVhZD4KICAgIDx0aXRsZT5FeGFtcGxlIERvbWFpbjwvdGl0bGU+CgogICAgPG1ldGEgY2hhcnNldD0idXRmLTgiIC8+CiAgICA8bWV0YSBodHRwLWVxdWl2PSJDb250ZW50LXR5cGUiIGNvbnRlbnQ9InRleHQvaHRtbDsgY2hhcnNldD11dGYtOCIgLz4KICAgIDxtZXRhIG5hbWU9InZpZXdwb3J0IiBjb250ZW50PSJ3aWR0aD1kZXZpY2Utd2lkdGgsIGluaXRpYWwtc2NhbGU9MSIgLz4KICAgIDxzdHlsZSB0eXBlPSJ0ZXh0L2NzcyI+CiAgICBib2R5IHsKICAgICAgICBiYWNrZ3JvdW5kLWNvbG9yOiAjZjBmMGYyOwogICAgICAgIG1hcmdpbjogMDsKICAgICAgICBwYWRkaW5nOiAwOwogICAgICAgIGZvbnQtZmFtaWx5OiAtYXBwbGUtc3lzdGVtLCBzeXN0ZW0tdWksIEJsaW5rTWFjU3lzdGVtRm9udCwgIlNlZ29lIFVJIiwgIk9wZW4gU2FucyIsICJIZWx2ZXRpY2EgTmV1ZSIsIEhlbHZldGljYSwgQXJpYWwsIHNhbnMtc2VyaWY7CiAgICAgICAgCiAgICB9CiAgICBkaXYgewogICAgICAgIHdpZHRoOiA2MDBweDsKICAgICAgICBtYXJnaW46IDVlbSBhdXRvOwogICAgICAgIHBhZGRpbmc6IDJlbTsKICAgICAgICBiYWNrZ3JvdW5kLWNvbG9yOiAjZmRmZGZmOwogICAgICAgIGJvcmRlci1yYWRpdXM6IDAuNWVtOwogICAgICAgIGJveC1zaGFkb3c6IDJweCAzcHggN3B4IDJweCByZ2JhKDAsMCwwLDAuMDIpOwogICAgfQogICAgYTpsaW5rLCBhOnZpc2l0ZWQgewogICAgICAgIGNvbG9yOiAjMzg0ODhmOwogICAgICAgIHRleHQtZGVjb3JhdGlvbjogbm9uZTsKICAgIH0KICAgIEBtZWRpYSAobWF4LXdpZHRoOiA3MDBweCkgewogICAgICAgIGRpdiB7CiAgICAgICAgICAgIG1hcmdpbjogMCBhdXRvOwogICAgICAgICAgICB3aWR0aDogYXV0bzsKICAgICAgICB9CiAgICB9CiAgICA8L3N0eWxlPiAgICAKPC9oZWFkPgoKPGJvZHk+CjxkaXY+CiAgICA8aDE+RXhhbXBsZSBEb21haW48L2gxPgogICAgPHA+VGhpcyBkb21haW4gaXMgZm9yIHVzZSBpbiBpbGx1c3RyYXRpdmUgZXhhbXBsZXMgaW4gZG9jdW1lbnRzLiBZb3UgbWF5IHVzZSB0aGlzCiAgICBkb21haW4gaW4gbGl0ZXJhdHVyZSB3aXRob3V0IHByaW9yIGNvb3JkaW5hdGlvbiBvciBhc2tpbmcgZm9yIHBlcm1pc3Npb24uPC9wPgogICAgPHA+PGEgaHJlZj0iaHR0cHM6Ly93d3cuaWFuYS5vcmcvZG9tYWlucy9leGFtcGxlIj5Nb3JlIGluZm9ybWF0aW9uLi4uPC9hPjwvcD4KPC9kaXY+CjwvYm9keT4KPC9odG1sPgo="}},
"route":"www.example.com:80",
"sid":"crugtkkdfur6asj5vbtg",
"duration":275290907,
"time":"2024-10-02T17:13:54.45553392+08:00"}
```

作为对比，如果不开启流量嗅探（sniffing选项为false），代理也会上报基本的请求信息：

```json
{"service":"service-0","network":"tcp","remote":"[::1]:38478","local":"[::1]:8080",
"host":"www.example.com:80","proto":"http","clientIP":"::1",
"http":{"host":"www.example.com:80","method":"CONNECT","proto":"HTTP/1.1","scheme":"","uri":"www.example.com:80","statusCode":200,
"request":{"contentLength":0,"header":{"Proxy-Connection":["Keep-Alive"],"User-Agent":["curl/8.5.0"]},"body":null},
"response":{"contentLength":0,"header":{"Proxy-Agent":["gost/3.0"]},"body":null}},
"route":"www.example.com:80",
"sid":"crugs4sdfur6173lghpg",
"duration":286770422,
"time":"2024-10-02T17:10:43.884912063+08:00"}
```

当通过代理请求`https://www.example.com`时，代理会嗅探到TLS协议，并在请求结束后上报TLS握手相关信息：

```bash
curl -x localhost:8080 https://www.example.com
```

```json
{"service":"service-0","network":"tcp","remote":"[::1]:47762","local":"[::1]:8080",
"host":"www.example.com:443","proto":"tls","clientIP":"::1",
"http":{"host":"www.example.com:443","method":"CONNECT","proto":"HTTP/1.1","scheme":"","uri":"www.example.com:443","statusCode":200,"request":{"contentLength":0,"header":{"Proxy-Connection":["Keep-Alive"],"User-Agent":["curl/8.5.0"]},"body":null},
"response":{"contentLength":0,"header":{"Proxy-Agent":["gost/3.0"]},"body":null}},
"tls":{"serverName":"www.example.com","cipherSuite":"TLS_CHACHA20_POLY1305_SHA256","compressionMethod":0,"proto":"h2","version":"tls1.3","clientHello":"1603010200010001fc030376cf0725e0fdd0eacbcd3a3812a7c485b9a6d8f56ba0be60e6478034fbb1d4fc20d9ba04c56294e5d47cf90e602ae9cc035a3dd5f3176282d5607c97ccfc67da11003e130213031301c02cc030009fcca9cca8ccaac02bc02f009ec024c028006bc023c0270067c00ac0140039c009c0130033009d009c003d003c0035002f00ff0100017500000014001200000f7777772e6578616d706c652e636f6d000b000403000102000a00160014001d0017001e00190018010001010102010301040010000e000c02683208687474702f312e31001600000017000000310000000d002a0028040305030603080708080809080a080b080408050806040105010601030303010302040205020602002b00050403040303002d00020101003300260024001d00202df40f29d72881390f179f1de16e0e90e98f7b1bc8c6a238598d6f494452926a001500b200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"serverHello":"160303007a02000076030347c2e7bbf9682466d474c3e73ba80b65814df3d31ed915790425525ff0080be920d9ba04c56294e5d47cf90e602ae9cc035a3dd5f3176282d5607c97ccfc67da11130300002e002b0002030400330024001d0020207342df1ceb5399e366b31045804b35e57d202818d59dcfba9f106297c83354"},
"route":"www.example.com:443",
"sid":"crugl5cdfur509g9qu40",
"duration":605161979,
"time":"2024-10-02T16:55:49.538015062+08:00"}
```

# TLS终止与MITM代理

!!! note "开启流量嗅探"
    MITM代理功能依赖流量嗅探，需要同时开启流量嗅探功能（sniffing选项设置为true）后才生效。

通过开启流量嗅探可以解析出TLS握手阶段的交互信息，但如果想更进一步嗅探到后续TLS加密传输的数据，就需要在代理服务端实现[TLS终止（TLS Termination）](https://www.haproxy.com/glossary/what-is-ssl-tls-termination)，也就是让客户端认为代理服务就是所要访问的目标服务端主机，从而在代理端对TLS数据进行解密。此过程也称作[中间人攻击(MITM)](https://zh.wikipedia.org/wiki/%E4%B8%AD%E9%97%B4%E4%BA%BA%E6%94%BB%E5%87%BB)，此时HTTP代理也是一个MITM代理，可以劫持TLS流量。

TLS流量劫持的关键是对私有CA根证书的信任，用我们提供的根证书来签发并替代原始主机的证书。仅当同时设置了正确的CA证书和私钥（mitm.certFile和mitm.keyFile）后才会开启TLS流量劫持。

以下是开启了MITM TLS流量劫持的HTTP代理，并仅对访问`example.com`及其子域名的TLS流量进行劫持。

!!! tip "生成CA根证书"
    借助于[openssl](https://github.com/openssl/openssl)命令，可以生成私有CA证书：

    ```bash
    # 生成根证书私钥ca.key文件
    openssl genrsa -out ca.key 2048
    # 生成自签名根证书ca.crt文件
    openssl req -new -x509 -days 365 -key ca.key -out ca.crt
    ```

```yaml hl_lines="19-26"
services:
  - name: service-0
    addr: :8080
    recorders:
      - name: recorder-0
        record: recorder.service.handler
        metadata:
          # 同时记录HTTP请求和响应体
          http.body: true
          # 记录的请求和响应体最大大小，默认最多记录1MB数据。
          http.maxBodySize: 1048576
    handler:
      type: http
      metadata:
        # 开启流量嗅探
        sniffing: true
        # 流量嗅探超时时长，当嗅探请求超时后，退回到简单的数据中转逻辑。
        sniffing.timeout: 3s
        # CA根证书文件
        mitm.certFile: ca.crt
        # CA根证书私钥文件
        mitm.keyFile: ca.key
        # 自定义ALPN协商结果
        mitm.alpn: h2
        # TLS流量劫持过滤
        mitm.bypass: mitm
    listener:
      type: tcp
recorders:
  - name: recorder-0
    http:
      url: http://localhost:8000
      timeout: 1s
bypasses:
  - name: mitm
    whitelist: true
    matchers:
      - .example.com
```

`mitm.certFile` (string, required)
:    CA根证书文件路径，用于签发服务端证书。

`mitm.keyFile` (string, required)
:    CA根证书私钥文件路径，用于签发服务端证书。

`mitm.alpn` (string)
:    指定TLS-ALPN协商结果，例如`h2`，`http/1.1`。

`mitm.bypass` (string)
:    Bypass名称，引用`bypasses.name`，通过bypass可以对指定的主机进行TLS流量劫持。


当通过代理请求`https://www.example.com`时，代理会嗅探到TLS协议，并执行TLS终止来对流量进行解密后再次嗅探解密后的流量，此时会同时嗅探到TLS握手信息和解密后的HTTP/2请求响应内容：

```bash
curl -k -x localhost:8080 https://www.example.com
```

```yaml
{"service":"service-0","network":"tcp","remote":"[::1]:56736","local":"[::1]:8080",
"host":"www.example.com:443","proto":"tls","clientIP":"::1",
"http":{"host":"www.example.com","method":"GET","proto":"HTTP/2.0","scheme":"https","uri":"/","statusCode":200,
"request":{"contentLength":0,"header":{"Accept":["*/*"],"User-Agent":["curl/8.5.0"]},"body":null},
"response":{"contentLength":1256,"header":{"Accept-Ranges":["bytes"],"Age":["487799"],"Cache-Control":["max-age=604800"],"Content-Type":["text/html; charset=UTF-8"],"Date":["Wed, 02 Oct 2024 10:28:35 GMT"],"Etag":["\"3147526947+gzip\""],"Expires":["Wed, 09 Oct 2024 10:28:35 GMT"],"Last-Modified":["Thu, 17 Oct 2019 07:18:26 GMT"],"Server":["ECAcc (sac/253C)"],"Vary":["Accept-Encoding"],"X-Cache":["HIT"]},
"body":"PCFkb2N0eXBlIGh0bWw+CjxodG1sPgo8aGVhZD4KICAgIDx0aXRsZT5FeGFtcGxlIERvbWFpbjwvdGl0bGU+CgogICAgPG1ldGEgY2hhcnNldD0idXRmLTgiIC8+CiAgICA8bWV0YSBodHRwLWVxdWl2PSJDb250ZW50LXR5cGUiIGNvbnRlbnQ9InRleHQvaHRtbDsgY2hhcnNldD11dGYtOCIgLz4KICAgIDxtZXRhIG5hbWU9InZpZXdwb3J0IiBjb250ZW50PSJ3aWR0aD1kZXZpY2Utd2lkdGgsIGluaXRpYWwtc2NhbGU9MSIgLz4KICAgIDxzdHlsZSB0eXBlPSJ0ZXh0L2NzcyI+CiAgICBib2R5IHsKICAgICAgICBiYWNrZ3JvdW5kLWNvbG9yOiAjZjBmMGYyOwogICAgICAgIG1hcmdpbjogMDsKICAgICAgICBwYWRkaW5nOiAwOwogICAgICAgIGZvbnQtZmFtaWx5OiAtYXBwbGUtc3lzdGVtLCBzeXN0ZW0tdWksIEJsaW5rTWFjU3lzdGVtRm9udCwgIlNlZ29lIFVJIiwgIk9wZW4gU2FucyIsICJIZWx2ZXRpY2EgTmV1ZSIsIEhlbHZldGljYSwgQXJpYWwsIHNhbnMtc2VyaWY7CiAgICAgICAgCiAgICB9CiAgICBkaXYgewogICAgICAgIHdpZHRoOiA2MDBweDsKICAgICAgICBtYXJnaW46IDVlbSBhdXRvOwogICAgICAgIHBhZGRpbmc6IDJlbTsKICAgICAgICBiYWNrZ3JvdW5kLWNvbG9yOiAjZmRmZGZmOwogICAgICAgIGJvcmRlci1yYWRpdXM6IDAuNWVtOwogICAgICAgIGJveC1zaGFkb3c6IDJweCAzcHggN3B4IDJweCByZ2JhKDAsMCwwLDAuMDIpOwogICAgfQogICAgYTpsaW5rLCBhOnZpc2l0ZWQgewogICAgICAgIGNvbG9yOiAjMzg0ODhmOwogICAgICAgIHRleHQtZGVjb3JhdGlvbjogbm9uZTsKICAgIH0KICAgIEBtZWRpYSAobWF4LXdpZHRoOiA3MDBweCkgewogICAgICAgIGRpdiB7CiAgICAgICAgICAgIG1hcmdpbjogMCBhdXRvOwogICAgICAgICAgICB3aWR0aDogYXV0bzsKICAgICAgICB9CiAgICB9CiAgICA8L3N0eWxlPiAgICAKPC9oZWFkPgoKPGJvZHk+CjxkaXY+CiAgICA8aDE+RXhhbXBsZSBEb21haW48L2gxPgogICAgPHA+VGhpcyBkb21haW4gaXMgZm9yIHVzZSBpbiBpbGx1c3RyYXRpdmUgZXhhbXBsZXMgaW4gZG9jdW1lbnRzLiBZb3UgbWF5IHVzZSB0aGlzCiAgICBkb21haW4gaW4gbGl0ZXJhdHVyZSB3aXRob3V0IHByaW9yIGNvb3JkaW5hdGlvbiBvciBhc2tpbmcgZm9yIHBlcm1pc3Npb24uPC9wPgogICAgPHA+PGEgaHJlZj0iaHR0cHM6Ly93d3cuaWFuYS5vcmcvZG9tYWlucy9leGFtcGxlIj5Nb3JlIGluZm9ybWF0aW9uLi4uPC9hPjwvcD4KPC9kaXY+CjwvYm9keT4KPC9odG1sPgo="}},
"tls":{"serverName":"www.example.com","cipherSuite":"TLS_AES_256_GCM_SHA384","compressionMethod":0,"proto":"h2","version":"tls1.3",
"clientHello":"1603010200010001fc03031a324876144e1406181bdf3aaa82474d857e645e42ed0c99659d118c636ff590207e005956244f53c6dd72e63ba6a82f6574acddb3d5fce8a9d1b356fe54849ef1003e130213031301c02cc030009fcca9cca8ccaac02bc02f009ec024c028006bc023c0270067c00ac0140039c009c0130033009d009c003d003c0035002f00ff0100017500000014001200000f7777772e6578616d706c652e636f6d000b000403000102000a00160014001d0017001e00190018010001010102010301040010000e000c02683208687474702f312e31001600000017000000310000000d002a0028040305030603080708080809080a080b080408050806040105010601030303010302040205020602002b00050403040303002d00020101003300260024001d002003cb950898f056e0bf91c1055b7842d6a56c596e9b50c6f37679ebce73dda737001500b200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
"serverHello":""},
"route":"www.example.com:443",
"sid":"crui0kkdfur17s14pcn0",
"duration":131862082,
"time":"2024-10-02T18:28:35.048920855+08:00"}
```

# 数据聚合与分析

GOST对于流量嗅探信息仅作上报操作，不会再进一步处理，如果需要对信息进行查询统计分析，可以把接收到的上报信息存储在ELK，Loki等日志聚合系统。你也可以选择直接使用[gost-plugins](https://github.com/ginuerzh/gost-plugins)中的记录器插件服务，其会将接收到的记录数据保存在MongoDB数据库中或推送给Loki服务。

```bash
docker run -p 8000:8000 ginuerzh/gost-plugins recorder --addr=:8000 --loki.url=http://loki.write:3100/loki/api/v1/push --loki.id=gost --mongo.uri=mongodb://mongo.db:27017 --mongo.db=gost
```

![Loki - HTTP](../../images/loki01.png) 

![Loki - DNS](../../images/loki02.png) 

![Mongo - HTTP](../../images/mongo01.png) 