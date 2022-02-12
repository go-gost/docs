# 动态配置

GOST可以通过WebAPI来进行动态配置，支持动态配置的对象有：服务(service)，转发链(chain)，认证器(auther)，分流器(bypass)，域名解析器(resolver)，域名IP映射器(hosts)。配置变更会立即生效。

!!! tip "不可变性"
    所有动态配置的对象均为不可变的实例。后续的更新操作会生成一个新的对象实例替换现有实例。

## 服务

通过WebAPI可以动态对服务进行配置。

### 新建服务

添加一个新的服务不会对现有服务造成影响，如果配置成功则服务立即生效。

```sh
curl https://latest.gost.run/play/webapi/config/services -d \
'{"name":"service-0","addr":":8080","handler":{"type":"http"},"listener":{"type":"tcp"}}'
```

### 更新服务

修改一个现有的服务会先导致此服务重启。

```sh
curl -X PUT https://latest.gost.run/play/webapi/config/services/service-0 -d \
'{"name":"service-0","addr":":8080","handler":{"type":"socks5"},"listener":{"type":"tcp"}}'
```

### 删除服务

删除一个现有服务会立即关闭并删除此服务。

```sh
curl -X DELETE https://latest.gost.run/play/webapi/config/services/service-0 
```

## 转发链

!!! tip "前向引用"
    GOST中的配置支持前向引用，当一个对象引用了另外一个对象(例如服务中通过chain来引用转发链)，所引用的对象可以不存在，后面可以通过增加此对象让引用生效。

### 新建转发链

转发链配置成功后，引用此转发链的对象会立即生效。

```sh
curl https://latest.gost.run/play/webapi/config/chains -d \
'{"name":"chain-0","hops":[{"name":"hop-0", 
"nodes":[{"name":"node-0","addr":":1080", 
"connector":{"type":"http"},"dialer":{"type":"tcp"}}]}]}'
```

### 更新转发链

使用请求的配置替换现有转发链对象。

```sh
curl -X PUT https://latest.gost.run/play/webapi/config/chains/chain-0 -d \
'{"name":"chain-0","hops":[{"name":"hop-0", 
"nodes":[{"name":"node-0","addr":":1080", 
"connector":{"type":"socks5"},"dialer":{"type":"tcp"}}]}]}'
```

### 删除转发链

```sh
curl -X DELETE https://latest.gost.run/play/webapi/config/chains/chain-0 
```
