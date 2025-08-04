# 命令行参数

## 参数说明

GOST有以下几个命令行参数项：

### **`-L` - 指定本地服务**

此参数值为类URL格式(方括号中的内容可以省略):

```
[scheme://][username:password@host]:port[?key1=value1&key2=value2]
```

或用于端口转发模式

```
scheme://[bind_address]:port/[host]:hostport[?key1=value1&key2=value2]
```

#### scheme

可以是处理器(Handler)与监听器(Listener)的组合，也可以是单独的处理器(监听器默认为tcp)或监听器(处理器默认为auto)，例如:

* `http+tls` - 处理器http与监听器tls的组合，指定HTTPS代理服务
* `http` - 等价于`http+tcp`，处理器http与监听器tcp的组合，指定HTTP代理服务
* `tcp` - 等价于`tcp+tcp`或`forward+tcp`，处理器tcp与监听器tcp的组合，指定TCP端口转发
* `tls` - 等价于`auto+tls`，处理器auto与监听器tls的组合

```bash
# http+tcp
gost -L http://:8080

# http+tcp -> socks5+tcp
gost -L http://:8080 -L socks5://:1080?foo=bar

# http+tls
gost -L http+tls://gost:gost@:8443

# auto+tls
gost -L tls://:8443

# tcp+tcp或forward+tcp
gost -L tcp://:8080/192.168.1.1:80

# 端口转发模式支持转发目标地址列表形式
gost -L tcp://:8080/192.168.1.1:80,192.168.1.2:80,192.168.1.3:8080
```

### **`-F` - 指定转发节点构成转发链**

此参数值为类URL格式(方括号中的内容可以省略):

```
[scheme://][username:password@host]:port[?key1=value1&key2=value2]
```

#### scheme

可以是连接器(Connector)与拨号器(Dialer)的组合，也可以是单独的连接器(拨号器默认为tcp)或拨号器(连接器默认为http)，例如:

* `http+tls` - 连接器http与拨号器tls的组合，指定HTTPS代理节点
* `http` - 等价与`http+tcp`，处理器http与监听器tcp的组合，指定HTTP代理节点
* `tls` - 等价与`http+tls`

```bash
# 支持多级转发
gost -L http://:8080 \
     -F http://gost:gost@192.168.1.1:8080 \
     -F socks5+tls://192.168.1.2:1080?foo=bar

# 也可以通过设置地址列表构成节点组
gost -L http://:8080 -F http://gost:gost@192.168.1.1:8080,192.168.1.2:8080
```

!!! note "特殊字符"

    在部分系统中某些字符(例如`&`，`!`)在命令行中具有特殊意义和功能，如果scheme包含这些特殊字符，请使用双引号`"`。

    ```bash
	gost -L http://:8080 -L "socks5://:1080?foo=bar&bar=baz"
	```

###  **`-C` - 指定外部配置文件路径或内容**

```bash
# 使用配置文件gost.yml
gost -C /etc/gost/gost.yml

# 直接使用JSON格式的配置内容
gost -C '{"api":{"addr":":8080"}}'

# 从标准输入(stdin)中读取配置
gost -C - < gost.yml
```

### **`-O` 指定配置输出格式**

目前支持`yaml`和`json`两种格式。

```bash
# 输出yaml格式配置
gost -L http://:8080 -O yaml

# 输出json格式配置
gost -L http://:8080 -O json

# 将json格式配置转成yaml格式
gost -C gost.json -O yaml

# 将yaml格式配置转成json格式
gost -C gost.yaml -O json
```

### **`-D` - 开启Debug级别日志**

Debug级别比Info级别有更详细的[日志](../../tutorials/log.md)输出，一般用于开发调试。

```bash
gost -L http://:8080 -D
```

### **`-DD` 开启Trace级别日志**

比Debug级别输出更详细的[日志](../../tutorials/log.md)信息。

```bash
gost -L http://:8080 -DD
```

### **`-V` - 查看版本**

显示GOST版本信息。

```bash
gost -V
# gost 3.0.0 (go1.24.0 linux/amd64)
```

### **`-api` - 指定WebAPI地址**

```bash
gost -L http://:8080 -api :18080
```

详细信息请参考[WebAPI](../../tutorials/api/overview.md)。

### **`-metrics` - 指定prometheus metrics API地址**

```bash
gost -L http://:8080 -metrics :9000
```

详细信息请参考[监控指标](../../tutorials/metrics.md)。

## 限定作用域参数

:material-tag: 3.2.1

命令行模式下设定的大部分参数默认会向下传递，例如对于服务会同时作用于服务(service)，服务中的监听器(listener)和处理器(handler)。
对于转发链则会作用于跳跃点(hop)，节点(node)以及节点中的拨号器(dialer)和连接器(connector)。

限定作用域参数是通过在参数前使用作用域限定前缀，来指定参数作用范围。

目前支持的限定前缀有：

* `service.` - 服务级别
* `listener.` - 监听器级别
* `handler.` - 处理器级别
* `hop.` - 跳跃点级别
* `node.` - 节点级别
* `dialer.` - 拨号器级别
* `connector.` - 连接器级别

=== "命令行"

    ```bash
    gost -L ":8080?handler.key1=value1&listener.key2=value2&service.key3=value3" \
         -F "http://:8000?hop.key4=value4&node.key5=value5&dialer.key6=value6&connector.key7=value7"
    ```

=== "配置文件"

    ```yaml
    services:
      - name: service-0
        addr: :8080
        handler:
          type: auto
          metadata:
            key1: value1
        listener:
          type: tcp
          metadata:
            key2: value2
        metadata:
          key3: value3
    chains:
      - name: chain-0
        hops:
          - name: hop-0
            nodes:
              - name: node-0
                addr: :8000
                connector:
                  type: http
                  metadata:
                    key7: value7
                dialer:
                  type: tcp
                  metadata:
                    key6: value6
                metadata:
                  key5: value5
            metadata:
              key4: value4
    ```

`key1`限定为handler级别参数，对应于`handler.metadata.key1`。

`key2`限定为listener级别参数，对应于`listener.metadata.key2`。

`key3`限定为service级别参数，对应于`service.metadata.key3`。

`key4`限定为hop级别参数，对应于`hop.metadata.key4`。

`key5`限定为node级别参数，对应于`node.metadata.key5`。

`key6`限定为dialer级别参数，对应于`dialer.metadata.key6`。

`key7`限定为connector级别参数，对应于`connector.metadata.key7`。


