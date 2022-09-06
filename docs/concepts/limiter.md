# 限速

!!! tip "动态配置"
    限速器支持通过Web API进行动态配置。

## 限速器

在每个服务上可以通过设置限速器来对请求进行限制，目前的限速器支持对上下行流量速率的限制，包括服务，连接和IP/CIDR三个级别的限速，三个级别可以组合使用。

=== "命令行"

    ```
    gost -L ":8080?limiter.rate.in=100MB&limiter.rate.out=100MB&limiter.rate.conn.in=10MB&limiter.rate.conn.out=10MB"
    ```

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
		- '$$ 10MB'
		- '192.168.1.1  512KB 1MB'
		- '192.168.0.0/16  1MB  5MB'
    ```

命令行中通过`limiter.rate.in`和`limiter.rate.out`来设置服务级别的限速，通过`limiter.rate.conn.in`和`limiter.rate.conn.out`来设置连接级别的限速。

配置文件中使用`limiter`参数通过引用限速器名称(`limiters.name`)来使用指定的限速器。

通过`rate.limits`选项指定配置列表，每一个配置项包含空格分割的三个部分：

* 作用域(Scope)：限速作用范围，IP地址或CIDR，例如192.168.1.1，192.168.0.0/16。其中两个特殊的值: `$`代表服务级别，`$$`代表连接级别。

* 入站速率(Input)：服务接收数据的速率(每秒流量)，支持的单位有: B，KB，MB，GB，TB，例如 128KB，1MB，10GB。

* 出站速率(Output)：服务发送数据的速率(每秒流量)，单位同入站速率。出站速率可选，不设置代表无限制。

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
	- $$ 10MB
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

文件格式为按行分割的限速配置列表，以`#`开始的部分为注释信息，每项配置格式同内联配置。

```yaml
# ip/cidr  input  output

$ 100MB  200MB
$$ 10MB
192.168.1.1  1MB 10MB
192.168.0.0/16  512KB  1MB
```

### Redis

指定redis服务作为数据源，redis数据类型必须为集合(Set)或列表(List)类型，每项配置格式同内联配置。

```yaml
limiters:
- name: limiter-0
  rate:
    redis:
      addr: 127.0.0.1:6379
      db: 1
      password: 123456
      key: gost:limiters:limiter-0
	  type: set
```

`addr` (string, required)
:    redis服务地址

`db` (int, default=0)
:    数据库名

`password` (string)
:    密码

`key` (string, default=gost)
:    redis key

`type` (string, default=set)
:    数据类型，支持的类型有：集合(`set`)，列表(`list`)。

## 优先级

当同时配置多个数据源时，优先级从高到低为: redis，文件，内联。如果在不同数据源中存在相同的作用域，则优先级高的会覆盖优先级低的配置。

## 热加载

文件和redis数据源支持热加载。通过设置`rate.reload`参数开启热加载，`reload`参数指定同步数据源数据的周期。

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
