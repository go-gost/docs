---
template: blog.html
author: ginuerzh
author_gh_user: ginuerzh
read_time: 5min
publish_date: 2015-12-18 18:05
---

原文地址：[https://groups.google.com/g/go-gost/c/32jXBP3pAxc](https://groups.google.com/g/go-gost/c/32jXBP3pAxc)。


[letsencrypt](https://letsencrypt.org/)在12月3号正式进行公测了，也就是说现在所有人都可以免费拥有自己的tls证书了，前提是服务器要绑定域名。

首先当然是要生成证书：

```bash
git clone https://github.com/letsencrypt/letsencrypt.git
cd letsencrypt
letsencrypt-auto certonly --email your_email@email.com -d your_host_domain.com
```

如果一切顺利的话，在/etc/letsencrypt/下会会生成live目录，进去后会有你的域名目录，再进去就是你的证书了。
我们只用到两个文件**cert.pem**和**privkey.pem**。

证书生成好了，下面就可以运行https代理了：

gost内置了一个tls证书，如果要使用自己的证书，需要在gost的运行目录中放置cert.pem和key.pem两个文件(key.pem即letsencrypt生成的privkey.pem)，

假如gost可执行文件在/home/abc目录下，可以将letsencrypt证书拷贝到此目录：

```bash
cd /home/abc
cp /etc/letsencrypt/live/your_host_domain.com/cert.pem /home/abc/cert.pem
cp /etc/letsencrypt/live/your_host_domain.com/privkey.pem /home/abc/key.pem
```

最后运行gost：

```
gost -L=http+tls://:443 -logtostderr -v=2
```

如果没有报'open cert.pem: no such file or directory'错误，则说明letsencrypt的证书加载成功。

浏览器端使用SwitchyOmega添加此https代理就可以使用了。