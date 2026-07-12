---
authors:
  - ginuerzh
categories:
  - VPN
readtime: 30
date: 2015-07-23
comments: true
---

# Global Proxy with PPTP, Redsocks, iptables, and HTTPS/SOCKS5 Proxy

Original posts:

[https://groups.google.com/g/go-gost/c/dzDQeTfNCjY](https://groups.google.com/g/go-gost/c/dzDQeTfNCjY)

[https://docs.google.com/document/d/1OGIrebKWq__Lt0ADxprxapevC1BEzPaR6ry9XY_WDdA](https://docs.google.com/document/d/1OGIrebKWq__Lt0ADxprxapevC1BEzPaR6ry9XY_WDdA)

<!-- more -->

## Use Case

When using a proxy to access the internet, you typically need to configure each application individually (if it supports proxies). It's difficult to make all network traffic go through the proxy by default.
On mobile devices (especially iPhones), without a VPN, it's hard to achieve global proxy functionality using only HTTPS or SOCKS5 proxies.

![REDIRECT](/images/redirect01.png)

Here, the Linux PC uses Ubuntu 14.04, the VPN uses PPTP, and the proxy uses SOCKS5.

## PPTP Server Installation & Configuration

Install the PPTP server:

```bash
sudo apt-get install pptpd
```

After installation, configure it.

Edit `/etc/pptpd.conf`, add these two lines:

```
localip 192.168.0.1
remoteip 192.168.0.234-238,192.168.0.245
```

`localip` is the PPTP server IP, `remoteip` is the IP range assigned to clients.

Edit `/etc/ppp/chap-secrets` to set PPTP authentication, add a new line at the end:

```
vpn	pptpd		123456	*
```

Here `vpn` is the username, `pptpd` is the VPN type (can be set to `*`), `123456` is the password, and `*` allows connections from any IP.

Edit `/etc/ppp/pptpd-options` to add DNS servers:

```
ms-dns 8.8.8.8
ms-dns 8.8.4.4
```

Finally, restart the PPTP server:

```bash
sudo service pptpd restart
```

Verify the service is running:

```bash
netstat -tlnp | grep 1723
```

## Linux System Configuration

Edit `/etc/sysctl.conf`, add:

```
net.ipv4.ip_forward=1
```

Apply changes:

```bash
sudo sysctl -p
```

## Redsocks Installation & Configuration

Redsocks works with iptables to redirect TCP connections.

Project info: [http://darkk.net.ru/redsocks/](http://darkk.net.ru/redsocks/)
Source: [https://github.com/darkk/redsocks](https://github.com/darkk/redsocks)

### Build redsocks

```bash
git clone https://github.com/darkk/redsocks.git
cd redsocks
sudo apt-get install libevent-dev
make
```

Create a config file `redsocks.conf`:

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

Run redsocks:

```bash
./redsocks -c redsocks.conf
```

## iptables Configuration

Create `ipt.conf`:

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
:REDSOCKS -

-A PREROUTING -i ppp+ -p tcp -j REDIRECT --to 31338
-A REDSOCKS -d 0.0.0.0/8 -j RETURN
-A REDSOCKS -d 10.0.0.0/8 -j RETURN
-A REDSOCKS -d 127.0.0.0/8 -j RETURN
-A REDSOCKS -d 169.254.0.0/16 -j RETURN
-A REDSOCKS -d 172.24.0.0/16 -j RETURN
-A REDSOCKS -d 192.168.0.0/16 -j RETURN
-A REDSOCKS -d 224.0.0.0/4 -j RETURN
-A REDSOCKS -d 240.0.0.0/4 -j RETURN
-A REDSOCKS -p tcp -j REDIRECT --to 31338
-A OUTPUT -p tcp -j REDSOCKS

-A POSTROUTING -s 192.168.0.0/24 -o eth0 -j MASQUERADE
COMMIT
```

Apply iptables rules:

```bash
sudo iptables-restore < ipt.conf
```

## Proxy Configuration

Any standard HTTPS or SOCKS5 proxy (e.g., Shadowsocks, GOST) can be used. The client's listening address should match the `ip` and `port` in the redsocks configuration.

Done!
