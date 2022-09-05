# 准入控制

!!! tip "动态配置"
    准入控制器支持通过Web API进行动态配置。

## 准入控制器

在每个服务上可以分别设置准入控制器来控制客户端接入。

=== "命令行"

    ```
    gost -L http://:8080?admission=127.0.0.1,192.168.0.0/16
    ```

	  通过`admission`参数来指定客户端地址匹配规则列表(以逗号分割的IP或CIDR)。

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      admission: admission-0
      handler:
        type: http
      listener:
        type: tcp
    admissions:
    - name: admission-0
      matchers:
      - 127.0.0.1
      - 192.168.0.0/16
    ```

    服务中使用`admission`属性通过引用准入控制器名称(name)来使用指定的准入控制器。

## 黑名单与白名单

与分流器类似，准入控制器也可以设置黑名单或白名单模式，默认为黑名单模式。

=== "命令行"

    ```
    gost -L http://:8080?admission=~127.0.0.1,192.168.0.0/16
    ```

    通过在`admission`参数中增加`~`前缀将准入控制器设置为黑名单模式。

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      admission: admission-0
      handler:
        type: http
      listener:
        type: tcp
    admissions:
    - name: admission-0
      whitelist: true
      matchers:
      - 127.0.0.1
      - 192.168.0.0/16
    ```

	  在`admissions`中通过设置`whitelist`属性为`true`来开启白名单模式。

## 控制器组

通过使用`admissions`属性来指定准入控制器列表来使用多个控制器，当任何一个控制器拒绝则代表请求拒绝。

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      admissions: 
      - admission-0
      - admission-1
      handler:
        type: http
      listener:
        type: tcp
    admissions:
    - name: admission-0
      whitelist: true
      matchers:
      - 192.168.0.0/16
      - 127.0.0.1
    - name: admission-1
      matchers:
      - 192.168.0.1
    ```

## 数据源

准入控制器可以配置多个数据源，目前支持的数据源有：内联，文件，redis。

### 内联

内联数据源是指直接在配置文件中通过`matchers`参数设置数据。

```yaml
admissions:
- name: admission-0
  matchers:
  - 127.0.0.1
  - 192.168.0.0/16
```

### 文件

指定外部文件作为数据源。通过`file.path`参数指定文件路径。

```yaml
admissions:
- name: admission-0
  file:
    path: /path/to/file
```

文件格式为按行分割的地址列表，以`#`开始的部分为注释信息。

```text
# ip or cidr

127.0.0.1
192.168.0.0/16
```

### Redis

指定redis服务作为数据源，redis数据类型必须为[集合(Set)类型](https://redis.io/docs/manual/data-types/#sets)。

```yaml
admissions:
- name: admission-0
  redis:
    addr: 127.0.0.1:6379
	db: 1
	password: 123456
	key: gost:admissions:admission-0
```

`addr` (string, required)
:    redis服务地址

`db` (int, default=0)
:    数据库名

`password` (string)
:    密码

`key` (string, default=gost)
:    redis key

## 热加载

文件和redis数据源支持热加载。通过设置`reload`参数开启热加载，`reload`参数指定同步数据源数据的周期。

```yaml
admissions:
- name: admission-0
  reload: 10s
  file:
    path: /path/to/file
  redis:
    addr: 127.0.0.1:6379
	db: 1
	password: 123456
	key: gost:admissions:admission-0
```
