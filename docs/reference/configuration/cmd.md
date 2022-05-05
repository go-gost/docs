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
	```
	gost -L http://:8080
	```
	```
	gost -L http://:8080 -L socks5://:1080?foo=bar
	```
	```
	gost -L http+tls://gost:gost@:8443
	```
	```
	gost -L tcp://:8080/192.168.1.1:80
	```
	```
	gost -L tls://:8443
	```

!!! tip "转发地址列表"
    端口转发模式支持转发目标地址列表形式：
	```
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
	```
    gost -L http://:8080 -F http://gost:gost@192.168.1.1:8080 -F socks5+tls://192.168.1.2:1080?foo=bar
	```

!!! tip "节点组"
    也可以通过设置地址列表构成节点组：
	```
	gost -L http://:8080 -F http://gost:gost@192.168.1.1:8080,192.168.1.2:8080
	```

> **`-C`** - 指定外部配置文件。

!!! example
    使用配置文件`gost.yml`
	```
    gost -C gost.yml
	```

> **`-O`** - 指定配置输出格式，目前支持yaml或json。

!!! example
	输出yaml格式配置
	```
	gost -L http://:8080 -O yaml
	```

	输出json格式配置
	```
    gost -L http://:8080 -O json
	```

	将json格式配置转成yaml格式
	```
	gost -C gost.json -O yaml
	```

> **`-D`** - 开启Debug模式，更详细的日志输出。

!!! example
	```
	gost -L http://:8080 -D
	```

> **`-V`** - 查看版本，显示当前运行的GOST版本号。

!!! example
    ```
	gost -V
	```

> **`-api`** - 指定WebAPI地址。

!!! example
	```
	gost -L http://:8080 -api :18080
	```

> **`-metrics`** - 指定prometheus metrics API地址。

!!! example
    ```
	gost -L http://:8080 -metrics :9000
	```