---
template: blog.html
author: ginuerzh
author_gh_user: ginuerzh
read_time: 5min
publish_date: 2015-12-23 22:28
---

原文地址：[https://groups.google.com/g/go-gost/c/aLj9ruoSp4U](https://groups.google.com/g/go-gost/c/aLj9ruoSp4U)。

国外的vps可以帮助我们科学上网，但使用时间长了，很可能会出现限流或不稳定的情况。
这时如果通过国内的vps作为中转，情况可能会有所改善。

这里假设国内vps地址是aliyun.com，国外vps地址是linode.com，有两种方法。

第一种可以称之为桥式：

先架好桥墩

国外vps上(linode.com)：

```
gost -L=:1080
```

国内vps上(aliyun.com)：

```
gost -L=:8080
````

然后连接各个桥墩，就可以过桥了：

本地：
```
gost -L=:8888 -F=http://aliyun.com:8080 -F=socks://linode.com:1080
```

这种方式，由于各vps之间是独立的，所以灵活性较好，在vps较多时可以任意组合。 


另外一种称之为链式：

先构建一个链：

国外vps上(linode.com)：
```
gost -L=:1080
```

国内vps上(aliyun.com)：
```
gost -L=http+tls://:443 -F=socks://linode.com:1080
```

然后构建本地链：

本地：
```
gost -L=:8888 -F=http+tls://aliyun.com:443
```

这种方式虽然没有第一种灵活，但可以通过设置国内vps为https或shadowsocks代理，让支持此类型代理的应用直连国内vps就可以科学上网了。
