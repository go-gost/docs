# KCP

KCP是GOST中的一种数据通道类型。KCP的实现依赖于[xtaci/kcp-go](https://github.com/xtaci/kcp-go)库。

## 示例

=== "命令行"

    ```
	gost -L kcp://:8443?c=/path/to/config/file
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: auto
	  listener:
		type: kcp
		metadata:
		  c: /path/to/config/file
	```

## 配置

GOST中内置了一套默认的KCP配置项，默认值与xtaci/kcptun中的一致。可以通过参数`c`指定外部配置文件，配置文件为JSON格式：

```json
{
    "key": "it's a secrect",
    "crypt": "aes",
    "mode": "fast",
    "mtu" : 1350,
    "sndwnd": 1024,
    "rcvwnd": 1024,
    "datashard": 10,
    "parityshard": 3,
    "dscp": 0,
    "nocomp": false,
    "acknodelay": false,
    "nodelay": 0,
    "interval": 40,
    "resend": 0,
    "nc": 0,
    "sockbuf": 4194304,
    "keepalive": 10,
    "snmplog": "",
    "snmpperiod": 60,
    "tcp": false
}
```

配置文件中的参数说明请参考[kcptun](https://github.com/xtaci/kcptun#usage)。

## 代理协议

KCP数据通道可以与各种代理协议组合使用。

### HTTP Over KCP

=== "命令行"

    ```bash
    gost -L http+kcp://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: kcp
    ```

### SOCKS5 Over KCP

=== "命令行"

    ```bash
    gost -L socks5+kcp://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: kcp
    ```

### Relay Over KCP

=== "命令行"

    ```bash
    gost -L relay+kcp://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: kcp
    ```

## 端口转发

KCP通道也可以用作端口转发，相当于在UDP端口转发服务基础上增加KCP传输协议。

### 服务端

=== "命令行"

    ```bash
    gost -L kcp://:8443/:8080 -L ss://:8080
    ```
	等同于
    ```bash
    gost -L forward+kcp://:8443/:8080 -L ss://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: kcp
      forwarder:
        nodes:
        - name: target-0
          addr: :8080
    - name: service-1
      addr: :8080
      handler:
        type: http
      listener:
        type: tcp
    ```

通过使用KCP数据通道的端口转发，给8080端口的Shadowsocks代理服务增加了KCP数据通道。

此时8443端口等同于：

```bash
gost -L ss+kcp://:8443
```