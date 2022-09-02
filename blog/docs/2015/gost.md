---
author: ginuerzh
author_gh_user: ginuerzh
read_time: 1min
publish_date: 2015-05-21 15:08
---

原文地址：[https://groups.google.com/g/go-gost/c/vKbJh1IPK7o](https://groups.google.com/g/go-gost/c/vKbJh1IPK7o)。

## GO语言实现的安全隧道

### 特性

1. 支持设置上层http代理。
2. 客户端可用作http(s), socks5代理。
3. 服务器端兼容标准的socks5协议, 可直接用作socks5代理, 并额外增加协商加密功能。
4. Tunnel UDP over TCP, UDP数据包使用TCP通道传输，以解决防火墙的限制。
5. 多种加密方式(tls,aes-256-cfb,des-cfb,rc4-md5等)。
6. 客户端兼容shadowsocks协议，可作为shadowsocks服务器。

二进制文件下载：[https://bintray.com/ginuerzh/gost/gost/view](https://bintray.com/ginuerzh/gost/gost/view)。
