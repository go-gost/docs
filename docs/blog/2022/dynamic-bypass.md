---
template: blog.html
author: ginuerzh
author_gh_user: ginuerzh
read_time: 15min
publish_date: 2022-05-03 12:17
comments: true
---

原文地址：[https://groups.google.com/g/go-gost/c/b9Z0BcqUArw](https://groups.google.com/g/go-gost/c/b9Z0BcqUArw)。

分流是指根据一定的规则让需要通过转发链的请求走转发链，不需要走转发链则绕过转发链。分流在GOST v3中通过分流器来实现(bypass)，具体的使用方式可以参考https://gost.run/concepts/bypass/。

GOST v3中新增了一个记录器模块(https://gost.run/concepts/recorder/)，可以看作是另外一种日志记录方式，有别于日志的是记录器可以针对特定的数据进行记录，例如记录服务的所有访问用户IP，所有访问的目标地址等。

分流器和记录器在GOST v3版本中都增加了对redis服务的支持，对于分流器可以从redis中动态加载规则，对于记录器则可以将数据记录到redis服务中。

利用以上的特性，就可以实现类似与COW(https://github.com/cyfdecyf/cow)所提供的自动分流功能，默认情况下请求不使用转发链，当请求失败后切换为使用转发链。

目前的记录器可以记录所有访问失败的目标地址，将这些地址记录到redis中，再将分流器的数据源设置为redis中与记录器所记录的key相同，这样就可以通过记录器间接的找出并动态更新需要使用转发链的请求目标地址，提供给分流器使用。

```yaml
services:
- name: service-0
  addr: ":8080"
  recorders:
  - name: recorder-0
    record: recorder.service.router.dial.address.error
  handler:
    type: http
    chain: chain-0
  listener:
    type: tcp
chains:
- name: chain-0
  hops:
  - name: hop-0
    bypass: bypass-0
    nodes:
    - name: node-0
      addr: 192.168.1.1:8080
      connector:
        type: http
      dialer:
        type: tcp
bypasses:
- name: bypass-0
  redis:
  addr: 127.0.0.1:6379
  db: 0
  password: 123456
  key: gost:bypasses:bypass-0
recorders:
- name: recorder-0
  redis:
  addr: 127.0.0.1:6379
  db: 0
  password: 123456
  key: gost:bypasses:bypass-0
  type: set
```

这种方法也存在一定的问题：

* 无法自动消除误判。当网络出问题时，会导致原本不需要使用转发链的请求目标地址也会被记录器记录。

* 此方式只对直连的请求建立连接时会报错的情况有效(例如请求超时，连接拒绝等)，对于连接建立成功但无响应数据的情况无效。

针对第一种情况，可以借助外部工具，定期检查记录列表中每一个地址的直连状态，如果直连成功则可以将其清除。

如果你有更好的解决方案，欢迎提出！