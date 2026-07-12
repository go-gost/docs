---
authors:
  - ginuerzh
categories:
  - General
readtime: 5
date: 2015-12-23
comments: true
---

# Using a Domestic VPS as an Intermediate Proxy to Forward Requests to a Foreign VPS

Original post: [https://groups.google.com/g/go-gost/c/aLj9ruoSp4U](https://groups.google.com/g/go-gost/c/aLj9ruoSp4U).

A foreign VPS can help us access the open internet, but over time, it may suffer from rate limiting or instability.
Using a domestic VPS as a relay can improve the situation.

<!-- more -->

Let's assume the domestic VPS address is `aliyun.com` and the foreign VPS address is `linode.com`. There are two approaches.

### Bridge Method

First, set up the bridge piers:

On the foreign VPS (linode.com):
```
gost -L=:1080
```

On the domestic VPS (aliyun.com):
```
gost -L=:8080
```

Then connect the piers to cross the bridge:

Local machine:
```
gost -L=:8888 -F=http://aliyun.com:8080 -F=socks://linode.com:1080
```

This approach offers better flexibility since the VPS nodes are independent, allowing arbitrary combinations when multiple VPS are involved.

### Chain Method

First, build a chain:

On the foreign VPS (linode.com):
```
gost -L=:1080
```

On the domestic VPS (aliyun.com):
```
gost -L=http+tls://:443 -F=socks://linode.com:1080
```

Then build the local chain:

Local machine:
```
gost -L=:8888 -F=http+tls://aliyun.com:443
```

Although less flexible than the bridge method, this approach allows the domestic VPS to act as an HTTPS or Shadowsocks proxy, enabling applications that support these proxy types to connect directly to the domestic VPS for internet access.
