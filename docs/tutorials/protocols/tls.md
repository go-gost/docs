# TLS

TLS是GOST中的一种数据通道类型。

!!! tip "TLS证书配置"
    TLS配置请参考[TLS配置说明](/tutorials/tls/)。

## 标准TLS服务

=== "命令行"

    ```
    gost -L tls://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: auto
      listener:
        type: tls
    ```

## 多路复用

GOST在TLS基础之上扩展出具有多路复用(Multiplex)特性的TLS传输类型(mtls)。多路复用基于[xtaci/smux](https://github.com/xtaci/smux)库。

=== "命令行"

    ```
    gost -L mtls://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: auto
      listener:
        type: mtls
    ```

## 代理协议

TLS数据通道可以与各种代理协议组合使用。

### HTTP Over TLS

=== "命令行"

    ```bash
    gost -L http+tls://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: tls
        # type: mtls
    ```

### SOCKS5 Over TLS

=== "命令行"

    ```bash
    gost -L socks5+tls://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: tls
        # type: mtls
    ```

### SS Over TLS

=== "命令行"

    ```bash
    gost -L ss+tls://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: ss
      listener:
        type: tls
        # type: mtls
    ```

## 端口转发

TLS通道也可以用作端口转发，相当于在TCP端口转发服务基础上增加TLS加密。

### 服务端

=== "命令行"

    ```bash
    gost -L tls://:8443/:8080 -L http://:8080
    ```
	等同于
    ```bash
    gost -L forward+tls://:8443/:8080 -L http://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: tls
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

通过使用TLS数据通道的端口转发，给8080端口的HTTP代理服务增加了TLS加密数据通道。

此时8443端口等同于：

```bash
gost -L http+tls://:8443
```