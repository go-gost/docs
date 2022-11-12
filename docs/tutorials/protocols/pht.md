# Plain HTTP Tunnel

PHT是GOST中的一种数据通道类型。

CONNECT方法并不是所有HTTP服务都支持，为了更加通用，GOST利用HTTP协议中更加常用的GET和POST方法来实现数据通道，包括加密的`phts`和明文的`pht`两种模式。

!!! tip "TLS证书配置"
    TLS配置请参考[TLS配置说明](/tutorials/tls/)。

## 不使用TLS

=== "命令行"

    ```bash
	gost -L "http+pht://:8443?authorizePath=/authorize&pushPath=/push&pullPath=/pull"
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
		type: pht
		metadata:
		  authorizePath: /authorize
		  pushPath: /push
		  pullPath: /pull
	```

## 使用TLS 

PHT over LTS。

=== "命令行"

    ```
	gost -L "http+phts://:8443?authorizePath=/authorize&pushPath=/push&pullPath=/pull"
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
		type: phts
		metadata:
		  authorizePath: /authorize
		  pushPath: /push
		  pullPath: /pull
	```

## 自定义请求路径

PHT通道由三部分组成：

* 授权 - 客户端在与服务端进行数据传输前需要获取服务端的授权码，通过`authorizePath`选项设置请求的URI，默认值为`/authorize`。
* 接收数据 - 客户端从服务端获取数据，通过`pullPath`选项设置请求的URI，默认值为`/pull`。
* 发送数据 - 客户端发送数据到服务端，通过`pushPath`选项设置请求的URI，默认值为`/push`。

!!! note "路径匹配验证“
    仅当客户端和服务端设定的path参数相同时，连接才能成功建立。

## 代理协议

PHT数据通道可以与各种代理协议组合使用。

### HTTP Over PHT

=== "命令行"

    ```bash
    gost -L http+pht://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: pht
        # type: phts
    ```

### SOCKS5 Over PHT

=== "命令行"

    ```bash
    gost -L socks5+pht://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: pht
        # type: phts
    ```

### SS Over PHT

=== "命令行"

    ```bash
    gost -L ss+pht://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: ss
      listener:
        type: pht
        # type: phts
    ```

## 端口转发

PHT通道也可以用作端口转发。

### 服务端

=== "命令行"

    ```bash
    gost -L pht://:8443/:1080 -L socks5://:1080
    ```
	等同于
    ```bash
    gost -L forward+pht://:8443/:1080 -L socks5://:1080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: pht
        # type: phts
      forwarder:
        nodes:
        - name: target-0
          addr: :1080
    - name: service-1
      addr: :1080
      handler:
        type: socks5
      listener:
        type: tcp
    ```

通过使用PHT数据通道的端口转发，给1080端口的SOCKS5代理服务增加了PHT数据通道。

此时8443端口等同于：

```bash
gost -L socks5+pht://:8443
```
