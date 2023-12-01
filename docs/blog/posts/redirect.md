---
authors:
  - ginuerzh
categories:
  - VPN
readtime: 10
date: 2017-01-16
comments: true
---

# Linux下基于L2TP/IPSec + iptables + gost实现全局网络访问

原文地址：[https://groups.google.com/g/go-gost/c/bx0fYx2jmG4](https://groups.google.com/g/go-gost/c/bx0fYx2jmG4)。

之前写过一篇[类似的文章](../2015/redirect.md)，是利用PPTP + iptables + redsocks，但由于新版IOS上已经不支持PPTP了，所以这里面就换用IPSec来实现。

<!-- more -->

新版的gost也已经支持透明代理，redsocks也可以省去了，所以理论上这种方法要比之前的简单许多。

首先安装IPSec VPN服务，网上有人已经写了个自动化脚本，就不用我们费心再一步一步安装了：[https://github.com/hwdsl2/setup-ipsec-vpn](https://github.com/hwdsl2/setup-ipsec-vpn)。

再把透明代理跑起来：

```bash
gost -L redirect://:12345 -F http2://SERVER_IP:443?ping=30
```

若要避免DNS污染，可以再利用DNS转发：

```bash
gost -L udp://:1053/8.8.8.8:53?ttl=5 -L redirect://:12345 -F http2://SERVER_IP:443?ping=30
```

剩下的就是iptables了，修改`/etc/iptables.rules`文件，在nat中增加：

```
-A PREROUTING -i eth+ -p udp --dport 53 -j DNAT --to LOCAL_IP:1053
-A PREROUTING -p tcp -j REDSOCKS

-A OUTPUT -p tcp -j REDSOCKS
-A REDSOCKS -d 0.0.0.0/8 -j RETURN
-A REDSOCKS -d 10.0.0.0/8 -j RETURN
-A REDSOCKS -d 127.0.0.0/8 -j RETURN
-A REDSOCKS -d 169.254.0.0/16 -j RETURN
-A REDSOCKS -d 192.168.0.0/16 -j RETURN
-A REDSOCKS -d 224.0.0.0/4 -j RETURN
-A REDSOCKS -d 240.0.0.0/4 -j RETURN
-A REDSOCKS -d SERVER_IP -j RETURN
-A REDSOCKS -p tcp -j REDIRECT --to-ports 12345
```

上面看上去是不是还是挺麻烦的，其实还有一种更简单的办法，就是利用端口转发，将VPN直接映射到本地：

```bash
gost -L udp://:500/SERVER_IP:500 -L udp://:4500/SERVER_IP:4500 -L udp://:1701/SERVER_IP:1701 -F http2://SERVER_IP:443
```

这样本地就不用安装配置任何东西就可以作为VPN服务了。
