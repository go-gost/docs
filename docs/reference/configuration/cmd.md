# 命令行参数

GOST目前有以下几个命令行参数项：

> **`-L`** - 指定本地服务，可设置多个。

此参数值为类URL格式(方括号中的内容可以省略):

```
[scheme://][username:password@host]:port[?key1=value1&key2=value2]
```

或用于端口转发模式

```
scheme://[bind_address]:port/[host]:hostport[?key1=value1&key2=value2]
```

`scheme`
:      可以是处理器(Handler)与监听器(Listener)的组合，也可以是单独的处理器(监听器默认为tcp)或监听器(处理器默认为auto)，例如:

       * `http+tls` - 处理器http与监听器tls的组合，指定HTTPS代理服务
       * `http` - 等价与`http+tcp`，处理器http与监听器tcp的组合，指定HTTP代理服务
	   * `tcp` - 等价与`tcp+tcp`，处理器tcp与监听器tcp的组合，指定TCP端口转发
	   * `tls` - 等价与`auto+tls`，处理器auto与监听器tls的组合

!!! example "示例"

	```bash
	gost -L http://:8080
	```

	```bash
	gost -L http://:8080 -L socks5://:1080?foo=bar
	```

	```bash
	gost -L http+tls://gost:gost@:8443
	```

	```bash
	gost -L tcp://:8080/192.168.1.1:80
	```

	```bash
	gost -L tls://:8443
	```

!!! tip "转发地址列表"
    端口转发模式支持转发目标地址列表形式：

	```bash
	gost -L tcp://:8080/192.168.1.1:80,192.168.1.2:80,192.168.1.3:8080
	```

> **`-F`** - 指定转发服务，可设置多个，构成转发链。

此参数值为类URL格式(方括号中的内容可以省略):

```
[scheme://][username:password@host]:port[?key1=value1&key2=value2]
```

`scheme`
:      可以是连接器(Connector)与拨号器(Dialer)的组合，也可以是单独的连接器(拨号器默认为tcp)或拨号器(连接器默认为http)，例如:

       * `http+tls` - 连接器http与拨号器tls的组合，指定HTTPS代理节点
       * `http` - 等价与`http+tcp`，处理器http与监听器tcp的组合，指定HTTP代理节点
	   * `tls` - 等价与`http+tls`

!!! example

	```bash
    gost -L http://:8080 -F http://gost:gost@192.168.1.1:8080 -F socks5+tls://192.168.1.2:1080?foo=bar
	```

!!! tip "节点组"
    也可以通过设置地址列表构成节点组：

	```bash
	gost -L http://:8080 -F http://gost:gost@192.168.1.1:8080,192.168.1.2:8080
	```

> **`-C`** - 指定外部配置文件路径或内容。

!!! example
    使用配置文件`gost.yml`

	```bash
    gost -C gost.yml
	```

	直接使用JSON格式的配置内容

	```bash
	gost -C '{"api":{"addr":":8080"}}'
	```

	从标准输入(stdin)中读取配置

	```bash
	gost -C - < gost.yml
	```

> **`-O`** - 指定配置输出格式，目前支持yaml或json。

!!! example
	输出yaml格式配置

	```bash
	gost -L http://:8080 -O yaml
	```

	输出json格式配置

	```bash
    gost -L http://:8080 -O json
	```

	将json格式配置转成yaml格式

	```bash
	gost -C gost.json -O yaml
	```

> **`-D`** - 开启Debug模式，更详细的日志输出。

!!! example

	```bash
	gost -L http://:8080 -D
	```

> **`-DD` - 开启Trace模式，比Debug模式输出更详细的日志信息。

!!! example

	```bash
	gost -L http://:8080 -DD
	```

> **`-V`** - 查看版本，显示当前运行的GOST版本号。

!!! example

    ```bash
	gost -V
	```

> **`-api`** - 指定WebAPI地址。

!!! example

	```bash
	gost -L http://:8080 -api :18080
	```

> **`-metrics`** - 指定prometheus metrics API地址。

!!! example

    ```bash
	gost -L http://:8080 -metrics :9000
	```

!!! tip "scheme参数在命令行中的问题"
    在部分系统中字符`?`或`&`在命令行中具有特殊意义和功能，如果scheme包含这些特殊字符，请使用双引号`"`。

    ```bash
	gost -L http://:8080 -L socks5://:1080?foo=bar
	```

	或

    ```bash
	gost -L http://:8080 -L "socks5://:1080?foo=bar&bar=baz"
	```
