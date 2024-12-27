---
comments: true
---

# Simple-obfs

Simple-obfs is a data channel type.

It is compatible with [shadowsocks/simple-obfs](https://github.com/shadowsocks/simple-obfs) and Android [Simple Obfuscation](https://play.google.com/store/apps/details?id=com.github.shadowsocks.plugin.obfs_local) plugin.

## Usage

### obfs-http

**Server**

```bash
gost -L=ss+ohttp://chacha20:123456@:8338
```

**Client**

```bash
gost -L=:8080 -F=ss+ohttp://chacha20:123456@server_ip:8338?host=bing.com
```

The client can customize the request host through the `host` parameter.

### obfs-tls 

**Server**

```bash
gost -L=ss+otls://chacha20:123456@:8338
```

**Client**

```bash
gost -L=:8080 -F=ss+otls://chacha20:123456@server_ip:8338?host=bing.com
```

The client can customize the request host through the `host` parameter.
