---
comments: true
---

# DTLS

DTLS是GOST中的一种数据通道类型。DTLS的实现依赖于[pion/dtls](https://github.com/pion/dtls)库。

!!! tip "TLS证书配置"
    TLS配置请参考[TLS配置说明](/tutorials/tls/)。

## DTLS服务

=== "命令行"

    ```bash
    gost -L dtls://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: auto
      listener:
        type: dtls
    ```

## 代理协议

DTLS数据通道可以与各种代理协议组合使用。

### HTTP Over DTLS

=== "命令行"

    ```bash
    gost -L http+dtls://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: dtls
    ```

### SOCKS5 Over DTLS

=== "命令行"

    ```bash
    gost -L socks5+dtls://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: dtls
    ```

### Relay Over DTLS

=== "命令行"

    ```bash
    gost -L relay+dtls://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: dtls
    ```

## 端口转发

DTLS通道也可以用作端口转发，相当于在UDP端口转发服务基础上增加TLS加密。

**服务端**

=== "命令行"

    ```bash
    gost -L dtls://:8443/:8080 -L http://:8080
    ```
	  等同于

    ```bash
    gost -L forward+dtls://:8443/:8080 -L http://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: dtls
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

通过使用DTLS数据通道的端口转发，给8080端口的HTTP代理服务增加了DTLS加密数据通道。

此时8443端口等同于：

```bash
gost -L http+dtls://:8443
```