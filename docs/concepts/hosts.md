# 主机IP映射

通过在服务或转发链中设置映射器，可以自定义域名解析。

!!! tip "动态配置"
    映射器支持通过[Web API](/tutorials/api/overview/)进行动态配置。

## 映射器

映射器是一个主机名到IP地址的映射表，通过映射器可在DNS请求之前对域名解析进行人为干预。当需要进行域名解析时，先通过映射器查找是否有对应的IP定义，如果有则直接使用此IP地址。如果映射器中没有定义，再使用DNS服务查询。

### 服务上的映射器

当服务中的处理器在与目标主机建立连接之前，会使用映射器对请求目标地址进行解析。

=== "命令行"
	```
	gost -L http://:8080?hosts=example.org:127.0.0.1,example.org:::1,example.com:2001:db8::1
	```

	通过`hosts`参数来指定映射表。映射项为以`:`分割的host:ip对，ip可以是ipv4或ipv6格式。

=== "配置文件"

    ```yaml hl_lines="4 10"
	services:
	- name: service-0
	  addr: ":8080"
      hosts: hosts-0
	  handler:
		type: http
	  listener:
		type: tcp
	hosts:
	- name: hosts-0
	  mappings:
	  - ip: 127.0.0.1
		hostname: example.org
	  - ip: ::1
		hostname: example.org
	  - ip: 2001:db8::1
		hostname: example.com
	```

	服务使用`hosts`属性通过引用映射器名称(name)来使用指定的映射器。

### 转发链上的映射器

转发链中可以在跳跃点上或节点上设置映射器，当节点上未设置映射器，则使用跳跃点上的映射器。

=== "命令行"
	```
	gost -L http://:8000 -F http://example.com:8080?hosts=example.com:127.0.0.1,example.com:2001:db8::1
	```

	通过`hosts`参数来指定映射表。`hosts`参数对应配置文件中hop级别的映射器。

=== "配置文件"

    ```yaml hl_lines="14 19"
	services:
	- name: service-0
	  addr: ":8000"
	  handler:
		type: http
		chain: chain-0
	  listener:
		type: tcp
	chains:
    - name: chain-0
      hops:
      - name: hop-0
	    # hop level hosts
        hosts: hosts-0
        nodes:
		- name: node-0
		  addr: example.com:8080
	      # node level hosts
          # hosts: hosts-0
		  connector:
			type: http
		  dialer:
			type: tcp
	hosts:
	- name: hosts-0
	  mappings:
	  - ip: 127.0.0.1
		hostname: example.com
	  - ip: 2001:db8::1
		hostname: example.com
	```

	转发链的hop或node中使用`hosts`属性通过引用映射器名称(name)来使用指定的映射器。

## DNS代理服务

映射器在DNS代理服务中会直接应用到DNS查询请求，用来实现自定义域名解析。

```
gost -L dns://:10053?dns=1.1.1.1&hosts=example.org:127.0.0.1,example.org:::1
```

此时通过此DNS代理服务查询example.org会匹配到映射器中的定义而不会使用1.1.1.1查询。详细信息请参考[DNS代理](/tutorials/dns/)。

## 域名通配符

映射器中的域名也支持以`.`开头的特殊通配符格式。

例如：`.example.org`匹配example.org， abc.example.org，def.abc.example.org等子域名。

在查询一个域名映射时，会先查找完全匹配项，如果没有找到再查找通配符项，如果没有找到再依次查找上级域名通配符。

例如：abc.example.org，会先查找abc.example.org映射值，如果没有则查找.abc.example.org通配符项，如果没有则继续依次查找.example.org和.org通配符项。

## 数据源

映射器可以配置多个数据源，目前支持的数据源有：内联，文件，redis。

#### 内联

内联数据源直接在配置文件中通过`mappings`参数设置数据。

```yaml
hosts:
- name: hosts-0
  mappings:
  - ip: 127.0.0.1
	hostname: example.com
  - ip: 2001:db8::1
	hostname: example.com
```

### 文件

指定外部文件作为数据源。通过`file.path`参数指定文件路径。

```yaml
hosts:
- name: hosts-0
  file:
    path: /path/to/file
```

文件格式为按行分割的映射项，每一行为用空格分割的IP-host对，以`#`开始的部分为注释信息。

```text
# ip host

127.0.0.1    example.com
2001:db8::1  example.com
```

!!! tip "系统hosts文件"

    文件数据源兼容系统本身的hosts文件格式，可以直接使用系统的hosts文件。

    ```yaml
    hosts:
    - name: hosts-0
    file:
      path: /etc/hosts
    ```

### Redis

指定redis服务作为数据源，redis数据类型为[集合(Set)](https://redis.io/docs/manual/data-types/#sets)或[列表(List)](https://redis.io/docs/manual/data-types/#lists)类型。

```yaml
hosts:
- name: hosts-0
  redis:
    addr: 127.0.0.1:6379
	db: 1
	password: 123456
	key: gost:hosts:hosts-0
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

数据的每一项与文件数据源的格式类似：

```redis
> SMEMBERS gost:hosts
1) "127.0.0.1 example.com"
2) "2001:db8::1 example.com"
```

## 优先级

当同时配置多个数据源时，优先级从高到低为: redis，文件，内联。

## 热加载

文件和redis数据源支持热加载。通过设置`reload`参数开启热加载，`reload`参数指定同步数据源数据的周期。

```yaml hl_lines="3"
hosts:
- name: hosts-0
  reload: 10s
  file:
    path: /path/to/file
  redis:
    addr: 127.0.0.1:6379
	db: 1
	password: 123456
	key: gost:hosts:hosts-0
```