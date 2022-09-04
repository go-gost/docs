---
template: blog.html
author: ginuerzh
author_gh_user: ginuerzh
read_time: 5min
publish_date: 2015-10-26 09:39
---

原文地址：[https://groups.google.com/g/go-gost/c/Cnh_4aeRVcg](https://groups.google.com/g/go-gost/c/Cnh_4aeRVcg)。

gost的想法是在2013年产生的，那一年也是我来到当前这家公司的第一年，进入公司后发现公司对网络的限制已经到了极限：只能通过公司的代理访问网络，并且在未申请更高权限的情况下只能访问baidu搜索，其他网站一律被封，然而我们的小组又是搞移动互联网的，所以平时开发和查资料很不方面。

当时我们有一个Linode VPS用于开发，公司也放行了此VPS个别端口的HTTP访问权限，于是就开始寻思着能不能利用这个Linode中转一下。
其实需求很简单：通过公司的代理，在本地与linode之间建立一个tunnel。

一开始在网上搜索了一下，没有找到满足的（也可能我没有发现），基本上都是直连，无法在有代理的环境中使用。接着就开始尝试着自己写一个，第一版的代码在：[https://github.com/ginuerzh/goproxy](https://github.com/ginuerzh/goproxy)，这一版功能很简单，使用的是HTTP轮询方式，所以效率也很低，不过勉强满足了上面的需求，可以访问了。

不久就发现，公司其实也放行了linode的443端口，并且支持http CONNECT请求，这样就可以建立长连接，提高数据传输效率了。马上就写了第二版：[https://github.com/ginuerzh/gohttptun2](https://github.com/ginuerzh/gohttptun2)，这一版的功能与现在的gost已经很像了，只是还是比较的简陋。

这一版使用了很长时间，也比较稳定，所以就没有继续更新了，直到后来发现了[c9.io](https://c9.io)，可以通过websocket中转数据，这个时候gost就产生了。

很多人知道gost是因为c9.io，然而gost不是专门在c9.io这种环境中使用的，而是正如上面所说，适合需要多级转发的场景，虽然这种场景比较少见。