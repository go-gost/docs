---
comments: true
---

# Simple-obfs

Simple-obfs是GOST支持的一种数据通道类型。

Simple-obfs兼容[shadowsocks/simple-obfs](https://github.com/shadowsocks/simple-obfs)和Android上的[Simple Obfuscation](https://play.google.com/store/apps/details?id=com.github.shadowsocks.plugin.obfs_local)插件。

## 使用说明

### obfs-http

**服务端**

```bash
gost -L=ss+ohttp://chacha20:123456@:8338
```

**客户端**

```bash
gost -L=:8080 -F=ss+ohttp://chacha20:123456@server_ip:8338?host=bing.com
```

客户端可以通过`host`参数自定义请求Host。

### obfs-tls 

**服务端**

```bash
gost -L=ss+otls://chacha20:123456@:8338
```

**客户端**

```bash
gost -L=:8080 -F=ss+otls://chacha20:123456@server_ip:8338?host=bing.com
```

客户端可以通过`host`参数自定义请求Host。
