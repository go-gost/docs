---
template: blog.html
author: ginuerzh
author_gh_user: ginuerzh
read_time: 10min
publish_date: 2016-09-06 21:31
---

原文地址：[https://groups.google.com/g/go-gost/c/_-akAbTe3ho](https://groups.google.com/g/go-gost/c/_-akAbTe3ho)。

前一个[帖子](../2016/tcp/)介绍了本地端口转发的使用，这里就再说说远程端口转发的使用。

gost远程端口转发的功能类似于ssh中-R参数的功能，与本地端口转发一样，也支持UDP和转发链。

还是用之前的场景：

假设有三台机器：local_host, proxy_host, remote_host

* local_host可以访问proxy_host和remote_host

* proxy_host无法访问local_host和remote_host

* remote_host可以访问local_host

proxy_host <- local_host <-> remote_host

注意proxy_host与local_host是单通的，也就是说local_host在防火墙的后面。

TCP远程端口转发的使用：

我们想在proxy_host上用ssh登陆到remote_host上，在local_host上执行：

```bash
gost -L=rtcp://:2222/remote_host:22 -F=socks://proxy_host:1080
```

这里假设proxy_host上部署了gost socks5代理并监听在1080端口上。这样gost就会(通过转发链)连接到proxy_host，并让proxy_host监听TCP 2222端口，当我们使用ssh连接proxy_host的2222端口时，就相当于连接到了remote_host的22端口了：

```bash
ssh -p 2222 root@localhost
```

UDP远程端口转发的使用：

我们现在想在proxy_host上访问remote_host上的DNS服务，在local_host上执行：

```bash
gost -L=rudp://:5353/remote_host:53 -F=socks://proxy_host:1080
```

这里假设proxy_host上部署了gost socks5代理并监听在1080端口上。这样gost就会(通过转发链)连接到proxy_host，在proxy_host上监听UDP 5353端口，当我们向proxy_host:5353发送UDP数据，就相当于发送到了remote_host:53上了：

```bash
dig @localhost -p 5353 www.google.com
```

**注意**: TCP远程端口转发使用了socks5 bind协议，所以转发链的末端(最后一个-F参数)一定要是socks5类型；
UDP远程端口转发使用了UDP-over-TCP，所以转发链的末端(最后一个-F参数)一定要是gost socks5类型。