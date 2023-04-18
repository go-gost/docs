# 数据记录

## 记录器

记录器可以用来记录特定数据，通过配置和引用不同的记录器类型将数据记录到不同的目标中。

```yaml hl_lines="4 5 6 12"
services:
- name: service-0
  addr: :8080
  recorders:
  - name: recorder-0
    record: recorder.service.router.dial.address
  handler:
    type: auto
  listener:
    type: tcp
recorders:
- name: recorder-0
  file:
    path: /path/to/recorder/file
    sep: "\n"
```

## 记录器类型

目前支持的记录器类型有：文件，redis。

### 文件

文件记录器将数据记录到指定文件。

```yaml
recorders:
- name: recorder-0
  file:
    path: /path/to/recorder/file
    sep: "\n"
```

`file.path` (string)
:    文件路径

`sep` (string)
:    记录分割符，如果设置则会在两条记录中间插入此分割符

### Redis

Redis记录器将数据记录到redis服务中。

```yaml
recorders:
- name: recorder-0
  redis:
    addr: 127.0.0.1:6379
    db: 1
    password: 123456
    key: gost:recorder:recorder-0
    type: set
```

`addr` (string, required)
:    redis服务地址

`db` (int, default=0)
:    数据库名

`password` (string)
:    密码

`key` (string, required)
:    redis key

`type` (string, default=set)
:    数据类型，支持的类型有集合(`set`)，有序集合(`sset`)，列表(`list`)。

## 使用记录器

通过`service.recorders`指定所使用的记录器列表。

```yaml
services:
- name: service-0
  addr: :8080
  recorders:
  - name: recorder-0
    record: recorder.service.router.dial.address
  - name: recorder-1
    record: recorder.service.router.dial.address.error
  handler:
    type: auto
  listener:
    type: tcp
```

`name` (string, required)
:    记录器名，引用定义的记录器

`record` (string, required)
:    记录对象

### 记录对象

目前支持的记录对象有：

`recorder.service.client.address`
:    所有访问服务的客户端地址

`recorder.service.router.dial.address`
:   所有访问的目标地址

`recorder.service.router.dial.address.error`
:   建立连接失败的目标地址

## 插件

记录器可以配置为使用外部插件服务，记录器会将数据转发给插件服务处理。当使用插件时其他参数无效。

```yaml
recorders:
- name: recorder-0
  plugin:
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

`addr` (string, required)
:    插件服务地址

`tls` (duration, default=null)
:    设置后将使用TLS加密传输，默认不使用TLS加密。
