---
template: blog.html
author: ginuerzh
author_gh_user: ginuerzh
read_time: 30min
publish_date: 2015-07-23 18:27
---

原文地址：

[https://groups.google.com/g/go-gost/c/dzDQeTfNCjY](https://groups.google.com/g/go-gost/c/dzDQeTfNCjY)。

[https://docs.google.com/document/d/1OGIrebKWq__Lt0ADxprxapevC1BEzPaR6ry9XY_WDdA/edit#heading=h.qh7wl45v71jq](https://docs.google.com/document/d/1OGIrebKWq__Lt0ADxprxapevC1BEzPaR6ry9XY_WDdA/edit#heading=h.qh7wl45v71jq)

## 使用场景

在使用代理上网的情况下，一般需要在每个应用中分别设置代理（如果应用支持代理），很难做到让所有网络流量默认都走代理。
在手机(特别是iphone)上如果不使用VPN，仅通过https或socks5代理也是很难实现类似VPN的全局代理功能。


![REDIRECT](/images/redirect01.png) 

这里linux pc使用ubuntu 14.04, vpn使用pptp, proxy使用socks5。

## pptp服务器安装配置

安装pptp服务器

```bash
sudo apt-get install pptpd
```

执行完上面命令后pptp服务器就安装好了，下面主要就是配置了。

配置pptp服务器

编辑`/etc/pptpd.conf`，增加以下两行：

```
localip 192.168.0.1
remoteip 192.168.0.234-238,192.168.0.245
```

这里localip指pptp服务端的IP, remoteip是客户端连接后分配的IP范围。

编辑`/etc/ppp/chap-secrets`，设置pptp认证信息，在最后面新增一行：

```
vpn	pptpd		123456	*
```

这里vpn是用户名，pptpd是vpn类型，可以设置为*，123456是密码，最后一个*表示接收任何IP的连接。

编辑`/etc/ppp/pptpd-options`，添加DNS服务器：

```
ms-dns 8.8.8.8
ms-dns 8.8.4.4
```

这里使用google的公共dns服务器，也可以指定你自己的dns服务器。

最后重启pptp服务器使以上设置生效：

```
sudo service pptpd restart
```

查看一下pptp服务是否正在运行：

```bash
netstat -tlnp | grep 1723
```

出现类似以下信息说明pptp服务正在运行：

```
tcp        0      0 0.0.0.0:1723            0.0.0.0:*               LISTEN      -
```

## 配置linux系统

编辑`/etc/sysctl.conf`，增加一行：

```
net.ipv4.ip_forward=1
```

使修改生效：

```bash
sudo sysctl -p
```

到此为止，pptp服务端就配置完了，可以使用手机测试一下。

## redsocks安装配置

redsocks可以配置linux下的iptables实现TCP连接的重定向功能

项目介绍：[http://darkk.net.ru/redsocks/](http://darkk.net.ru/redsocks/)

项目源码：[https://github.com/darkk/redsocks](https://github.com/darkk/redsocks)

### 下载编译redsocks

```bash
git clone https://github.com/darkk/redsocks.git
cd redsocks
sudo apt-get install libevent-dev
make
```

没有错误的话会生成一个名为redsocks的可执行文件。

新建一个redsocks配置文件redsocks.conf，内容如下：

```text
base {
	log_debug = on; 
	log_info = on; 
	log = "file:/tmp/reddi.log"; 
	daemon = on; 
	redirector = iptables;
}

redsocks { 
	local_ip = 0.0.0.0; 
	local_port = 31338; 
	ip = 127.0.0.1; 
	port = 8899; 
	type = socks5; 
}
```

这里的local_ip, local_port是redsocks服务的监听地址，ip, port为代理的地址，type指定代理类型。

运行redsocks:

```bash
./redsocks -c redsocks.conf
```

因为在配置文件里面指定了后台运行(daemon=on)，所以执行以上命令后会直接出现命令行提示符，不会阻塞。

## iptables设置

下面是最复杂也是最容易出问题的环节。

新建文件`ipt.conf`，内容如下：

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

-A PREROUTING -i ppp+ -p tcp -j REDIRECT --to 31338
# -A PREROUTING -i ppp+ -p udp --dport 53 -j DNAT --to 192.168.1.1:53
# -A INPUT -p tcp --dport 1723 -j ACCEPT
# -A INPUT -p tcp --dport 47 -j ACCEPT
# -A INPUT -p gre -j ACCEPT

# Ignore LANs and some other reserved addresses.
# See http://en.wikipedia.org/wiki/Reserved_IP_addresses#Reserved_IPv4_addresses
# and http://tools.ietf.org/html/rfc5735 for full list of reserved networks.
-A REDSOCKS -d 0.0.0.0/8 -j RETURN
-A REDSOCKS -d 10.0.0.0/8 -j RETURN
-A REDSOCKS -d 127.0.0.0/8 -j RETURN
-A REDSOCKS -d 169.254.0.0/16 -j RETURN
-A REDSOCKS -d 172.24.0.0/16  -j RETURN
-A REDSOCKS -d 192.168.0.0/16 -j RETURN
-A REDSOCKS -d 224.0.0.0/4 -j RETURN
-A REDSOCKS -d 240.0.0.0/4 -j RETURN
# Anything else should be redirected to port 31338
# -A REDSOCKS -p tcp -o eth0 -j DNAT --to 127.0.0.1:31338
-A REDSOCKS -p tcp -j REDIRECT --to 31338
-A OUTPUT -p tcp -j REDSOCKS

-A POSTROUTING -s 192.168.0.0/24 -o eth0 -j MASQUERADE
COMMIT
```

是不是很复杂，当然如果你很了解iptables，这就是小菜一碟了。
如果你的系统本身配置了iptables，请根据自身网络情况适当修改。

在上面的配置文件中，有几个方面需要注意：

1. 如果你在配置vpn时，将dns设置为8.8.8.8和8.8.4.4，且你的系统又无法访问此dns服务器，这时就要设置dns转发了：

```
-A PREROUTING -i ppp+ -p udp --dport 53 -j DNAT --to 192.168.1.1:53
```

这里的`--to 192.168.1.1:53`就是用来设置转发到的dns服务器地址。

2. 配置中的eth0为系统访问外网的接口，一般情况下为eth0，当有多个接口时会出现eth1, eth2等等，可以通过`ifconfig`命令查看自己使用的是哪个接口。

应用iptable设置：

```bash
sudo iptables-restore < ipt.conf
```

执行完以上命令后配置中方的iptables规则就会立即生效了，可以通过以下命令确认：

```bash
sudo iptables-save
```

看看输出结果是否与ipt.conf中的一致。

## 代理配置

可以使用任何标准的https, socks5代理，例如shadowsocks, gost等，客户端的监听地址需要与redsocks配置中的ip, port一致。

## OK

DONE！

如果你成功走到了这里，恭喜你，你可以让你的手机，PC无障碍的通过代理全局上网了。


