# 限速

!!! tip "动态配置"
    限速器支持通过Web API进行动态配置。

## 限速器

在每个服务上可以通过设置限速器来对请求进行限制，目前的限速器支持对上下行流量速率的限制，包括服务，连接和IP/CIDR三个级别的限速。

=== "命令行"
    ```
    gost -L ":8080?limiter.rate.in=100MB&limiter.rate.out=100MB&limiter.rate.conn.in=10MB&limiter.rate.conn.out=10MB"
    ```

	通过`limiter.rate.in`和`limiter.rate.out`来设置服务级别的限速。

	通过`limiter.rate.conn.in`和`limiter.rate.conn.out`来设置连接级别的限速。

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
	  limiter: limiter-0
      handler:
        type: auto
      listener:
        type: tcp
    limiters:
    - name: limiter-0
	  rate:
	    limits:
		- '$ 100MB 100MB'
		- '$$ 10MB 10MB'
		- '192.168.1.1  512KB 1MB'
		- '192.168.0.0/16  1MB  5MB'
    ```

    使用`limiter`参数通过引用限速器名称(`limiters.name`)来使用指定的限速器。

	`$`代表服务级别，`$$`代表连接级别。


## 数据源

限速器可以配置多个数据源，目前支持的数据源有：内联，文件，redis。

### 内联

内联数据源是指直接在配置文件中通过`rate.limits`参数设置数据。

```yaml
limiters:
- name: limiter-0
  rate:
    limits:
	- $ 100MB  200MB
	- $$ 10MB  20MB
	- 192.168.1.1  1MB 10MB
	- 192.168.0.0/16  512KB  1MB
```

### 文件

指定外部文件作为数据源。通过`rate.file.path`参数指定文件路径。

```yaml
limiters:
- name: limiter-0
  rate:
	file:
      path: /path/to/file
```

文件格式为按行分割的列表，以`#`开始的部分为注释信息。

```text
# ip/cidr  input  output

$ 100MB  200MB
$$ 10MB  20MB
192.168.1.1  1MB 10MB
192.168.0.0/16  512KB  1MB
```

### Redis

指定redis服务作为数据源，redis数据类型必须为集合(Set)或列表(List)类型。

```yaml
limiters:
- name: limiter-0
  rate:
    redis:
      addr: 127.0.0.1:6379
      db: 1
      password: 123456
      key: gost:limiters:limiter-0
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
limiters:
- name: limiter-0
  rate:
    reload: 60s
    file:
      path: /path/to/file
    redis:
      addr: 127.0.0.1:6379
	  db: 1
	  password: 123456
	  key: gost:limiters:limiter-0
```
