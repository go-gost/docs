---
authors:
  - ginuerzh
categories:
  - Port Forwarding
readtime: 10
date: 2016-08-31
comments: true
---

# gost 2.1本地端口转发功能的使用说明

原文地址：[https://groups.google.com/g/go-gost/c/_Bn0oDKants](https://groups.google.com/g/go-gost/c/_Bn0oDKants)。

[2.1版本](https://github.com/ginuerzh/gost/tree/2.1)正在开发中，主要增加端口转发功能，这里主要说一下本地端口转发的使用。

gost的本地端口转发功能类似于ssh中 -L参数的功能(ssh端口转发的使用可以参考[这篇文章](http://www.ruanyifeng.com/blog/2011/12/ssh_port_forwarding.html))，而与ssh的区别在于：

1. gost支持UDP端口的转发。
2. gost支持通过转发链进行端口转发。

<!-- more -->

假设有三台机器：local_host, proxy_host, remote_host

* local_host就是本地我们正在使用的主机，可以访问proxy_host但不能直接访问remote_host，

* proxy_host为代理主机，可以访问local_host和remote_host，

* remote_host为远程的一台主机，与proxy_host连通。

local_host <-> proxy_host <-> remote_host

先说说TCP端口转发的使用：

我们想在local_host上用ssh登录到remote_host上(22端口)就可以使用本地端口转发功能了：

```bash
gost -L=tcp://:2222/remote_host:22 -F proxy_host:8080
```

这里假设proxy_host上部署了http代理并监听在8080端口上。

然后在local_host执行：

```bash
ssh -p 2222 root@localhost
```

就可以登录到remote_host上了。

再来看看UDP端口转发的使用：

还是上面的场景，现在想访问remote_host上的UDP 53端口，也就是DNS服务：

```bash
gost -L=udp://:5353/remote_host:53 -F socks://proxy_host:1080
```

这里假设proxy_host上部署了gost socks5代理并监听在1080端口上。

然后在local_host上执行：

```bash
dig @localhost -p 5353 www.google.com
```

此时就相当于访问到remote_host的UDP 53端口。

**注意**: UDP的端口转发使用了UDP-over-TCP，所以转发链的末端(最后一个-F参数)一定要是gost socks5类型。