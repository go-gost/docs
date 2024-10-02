---
comments: true
---

# Traffic Sniffing and MITM

By default, the data interaction between the client and the server is transparent to the intermediate proxy and forwarding services. Except for some services (such as SNI proxy, transparent proxy, DNS proxy, etc.) that need to obtain the target host address based on the information in the request, they simply forward the passing traffic without knowing the content of the forwarded data.


Sometimes we may need to conduct further analysis of the traffic, so that we can achieve real-time monitoring and statistical analysis of the traffic, which can also better assist developers in protocol debugging.

!!! note "Protocol Support"
    Traffic sniffing currently supports HTTP/1, HTTP/2, TLS and DNS protocols.

## Traffic Sniffing

Traffic sniffing refers to the analysis of the transferred traffic, generally matching the protocol of the client's first request data. In most cases, it checks whether it is an HTTP or TLS request. If the conditions are met, the subsequent data interaction will be parsed according to a specific protocol, so that the specific communication content can be obtained.


Most proxy and forwarding services in GOST support traffic sniffing. Traffic sniffing needs to be combined with a [recorder](../concepts/recorder.md) plugin, and the service will report the sniffed content in real time through the recorder.

For example, the following is an HTTP proxy service with traffic sniffing enabled. After the proxy negotiation phase is over, it will further check the traffic and try to sniff out HTTP or TLS traffic.

```yaml hl_lines="8-11 15-18"
services:
  - name: service-0
    addr: :8080
    recorders:
      - name: recorder-0
        record: recorder.service.handler
        metadata:
          # Also record both HTTP request and response body.
          http.body: true
          # The maximum size of the request and response body to be recorded. 
          # By default, a maximum of 1MB of data is recorded.
          http.maxBodySize: 1048576
    handler:
      type: http
      metadata:
        # Enable traffic sniffing.
        sniffing: true
        # Traffic sniffing timeout. When the sniffing request times out, it will fall back to the simple data transfer logic.
        sniffing.timeout: 3s
    listener:
      type: tcp
recorders:
  - name: recorder-0
    http:
      url: http://localhost:8000
      timeout: 1s
```

When a request to `http://www.example.com` is made through the proxy, the proxy will sniff the HTTP protocol and report the HTTP request/response information after the request is completed:

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

In contrast, if traffic sniffing is not enabled (the sniffing option is false), the proxy will also report basic request information:

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

When the request to `https://www.example.com` is made through the proxy, the proxy will sniff the TLS protocol and report TLS handshake related information after the request is completed:

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

## TLS Termination and MITM Proxy

!!! note "Enable traffic sniffing"
    The MITM proxy function relies on traffic sniffing and will only take effect after the traffic sniffing function is enabled (the sniffing option is set to true).

By enabling traffic sniffing, you can parse the interactive information in the TLS handshake phase. However, if you want to further sniff the subsequent TLS encrypted transmission data, you need to implement [TLS Termination](https://www.haproxy.com/glossary/what-is-ssl-tls-termination) on the proxy server, that is, let the client think that the proxy service is the target server host to be accessed, so as to decrypt the TLS data on the proxy side. This process is also called a [Man-in-the-middle attack (MITM)](https://en.wikipedia.org/wiki/Man-in-the-middle_attack). At this time, the HTTP proxy is also a MITM proxy, which can hijack TLS traffic.

The key to TLS traffic hijacking is to trust the private CA root certificate, and use the root certificate we provide to issue and replace the certificate of the original host. TLS traffic hijacking will only be enabled when the correct CA certificate and private key (`mitm.certFile` and `mitm.keyFile` options) are set at the same time.

!!! tip "Generate CA root certificate"
    With the help of [openssl](https://github.com/openssl/openssl) command, you can generate a private CA certificate:

    ```bash
    # Generate the CA private key file ca.key.
    openssl genrsa -out ca.key 2048
    # Generate the self-signed CA certificate file ca.crt. 
    openssl req -new -x509 -days 365 -key ca.key -out ca.crt
    ```

The following is an HTTP proxy with TLS traffic hijacking enabled, which only hijacks TLS traffic to `example.com` and its subdomains.

```yaml hl_lines="19-26"
services:
  - name: service-0
    addr: :8080
    recorders:
      - name: recorder-0
        record: recorder.service.handler
        metadata:
          # Also record both HTTP request and response body.
          http.body: true
          # The maximum size of the request and response body to be recorded. 
          # By default, a maximum of 1MB of data is recorded.
          http.maxBodySize: 1048576
    handler:
      type: http
      metadata:
        # Enable traffic sniffing.
        sniffing: true
        # Traffic sniffing timeout. When the sniffing request times out, it will fall back to the simple data transfer logic.
        sniffing.timeout: 3s
        # The CA root certificate file.
        mitm.certFile: ca.crt
        # The CA private key file.
        mitm.keyFile: ca.key
        # Customize ALPN negotiation result
        mitm.alpn: h2
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
:    The CA root certificate file path, which is used to issue server certificates.

`mitm.keyFile` (string, required)
:    The CA private key file path, which is used to issue server certificates.

`mitm.alpn` (string)
:    Specifies the TLS-ALPN negotiation result, for example `h2`，`http/1.1`.

`mitm.bypass` (string)
:    Bypass name, reference to `bypasses.name`. Bypass can be used to hijack TLS traffic on the specified host.

When requesting `https://www.example.com` through the proxy, the proxy will sniff the TLS protocol, perform TLS termination to decrypt the traffic, and then sniff the decrypted traffic again, so it will further sniff the decrypted HTTP/2 request/response content:

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

## Data Aggregation And Analysis

GOST only reports the traffic sniffing information and does not process it further. If you need to query, count and analyze the information, you can store the received reported information in a log aggregation system such as [ELK](https://www.elastic.co/cn/elastic-stack), [Grafana Loki](https://grafana.com/oss/loki/), etc.

You can also choose to use the recorder plugin service in [gost-plugins](https://github.com/ginuerzh/gost-plugins) directly, which will save the received data in a MongoDB database or push it to the Loki service.

```bash
docker run -p 8000:8000 ginuerzh/gost-plugins  \
  recorder --addr=:8000 --loki.url=http://loki.write:3100/loki/api/v1/push --loki.id=gost \
  --mongo.uri=mongodb://mongo.db:27017 --mongo.db=gost
```

![Loki - HTTP](/images/loki01.png) 

![Loki - DNS](/images/loki02.png) 

![Mongo - HTTP](/images/mongo01.png) 