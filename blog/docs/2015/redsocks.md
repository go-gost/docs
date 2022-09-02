---
author: ginuerzh
author_gh_user: ginuerzh
read_time: 10min
publish_date: 2015-11-19 21:25
---

原文地址：[https://groups.google.com/g/go-gost/c/c7QCorgZiLU](https://groups.google.com/g/go-gost/c/c7QCorgZiLU)。

之前写过一个[类似的文档](../2015/redirect.md)，不过因为参杂了vpn配置，所以略微复杂，下面是简化版。

在linux下的应用若要使用socks5代理，一般都需要在应用内手动设置，而且有些应用不支持设置代理功能。
其实可以通过redsocks+iptables来实现类似于vpn功能，将所有tcp流量重定向到socks5代理(也支持https代理)。

步骤如下：

1. 安装redsocks:

ubuntu下：
```
sudo apt-get install redsocks
```

如果没有此软件，则只能自己下源码编译 [https://github.com/darkk/redsocks](https://github.com/darkk/redsocks)。


2. 配置redsocks:

新建一个配置文件redsocks.conf，内容如下：

```
base {
        log_debug = off;
        log_info = on;
        log = "file:/tmp/reddi.log";

        daemon = on;
        redirector = iptables;
}

redsocks {
        local_ip = 127.0.0.1;
        local_port = 31338;

        ip = 127.0.0.1;
        port = 8888;
        type = socks5;
}
```

配置项里面的port指的就是socks5代理的端口(这里使用的是8888)。

然后执行redsocks:

```
redsocks -c redsocks.conf
```


通过netstat查看是否运行正常(监听在31338端口):

```bash
netstat -tlnp
```

![netstat](../images/redsocks.png)

查看日志:

```bash
tail -f /tmp/reddi.log
```

3. 配置iptables，新建配置文件ipt.conf，内容如下：

```
*filter
:INPUT ACCEPT
:FORWARD ACCEPT
:OUTPUT ACCEPT
COMMIT

*nat
:PREROUTING ACCEPT
:INPUT ACCEPT
:OUTPUT ACCEPT
:POSTROUTING ACCEPT
# Create new chain
:REDSOCKS - 

-A REDSOCKS -d 0.0.0.0/8 -j RETURN
-A REDSOCKS -d 10.0.0.0/8 -j RETURN
-A REDSOCKS -d 127.0.0.0/8 -j RETURN
-A REDSOCKS -d 169.254.0.0/16 -j RETURN
-A REDSOCKS -d 192.168.0.0/16 -j RETURN
-A REDSOCKS -d 224.0.0.0/4 -j RETURN
-A REDSOCKS -d 240.0.0.0/4 -j RETURN
-A REDSOCKS -d proxy_server_ip -j RETURN
# Anything else should be redirected to port 31338
-A REDSOCKS -p tcp -j REDIRECT --to 31338
-A OUTPUT -p tcp -j REDSOCKS

COMMIT
```

**注(这一步很重要)**：配置中红色标明的proxy_server_ip指的是本地代理软件所连接的远程服务器ip地址，用gost为例：

```
gost -L :8888 -F a.b.c.d:8080
```

要将proxy_server_ip替换为a.b.c.d

如果是shadowsocks，就是shadowsocks配置文件中的server项

最后应用iptables配置：

```
sudo iptables-restore < ipt.conf
```

结束！