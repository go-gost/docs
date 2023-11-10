# SSH

SSH是GOST中的一种数据通道类型。

SSH有两种模式：隧道模式和转发模式。

## 隧道模式

**服务端**

=== "命令行"

    ```bash
    gost -L relay+ssh://:2222
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: relay
      listener:
        type: ssh
    ```

**客户端**

=== "命令行"

    ```bash
    gost -L :8080 -F relay+ssh://:2222
    ```

=== "配置文件(YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: auto
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :2222
          connector:
            type: relay
          dialer:
            type: ssh
    ```

## 转发模式

采用标准SSH协议的端口转发功能，仅支持TCP。

**服务端**

=== "命令行"

    ```bash
    gost -L sshd://:2222
    ```

=== "配置文件(YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: sshd
      listener:
        type: sshd
    ```

**客户端**

=== "命令行"

    ```bash
    gost -L tcp://:8080/:80 -F sshd://:2222
    ```

=== "配置文件(YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: tcp
        chain: chain-0
      listener:
        type: tcp
	  forwarder:
	    nodes:
		- name: target-0
		  addr: :80
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :2222
          connector:
            type: sshd
          dialer:
            type: sshd
    ```

!!! tip "使用系统本身的SSH服务"
    在转发模式下服务端可以直接使用系统本身的SSH服务，例如Linux中的[OpenSSH(sshd)服务](https://linux.die.net/man/8/sshd)。

## 认证

SSH支持用户名/密码认证和PubKey认证两种认证方式。

### 用户名/密码认证

!!! caution "认证信息作用对象"
    在命令行模式下，认证信息(user:pass)设置的是SSH通道的认证(Listener和Dialer)，而非Handler和Connector。
	此行为仅在使用ssh和sshd通道时有效。

**服务端**

=== "命令行"

    ```bash
    gost -L relay+ssh://user:pass@:2222
    ```
	  或

    ```bash
    gost -L sshd://user:pass@:2222
    ```

=== "配置文件(YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: relay
      listener:
        type: ssh
        auth:
          username: user
          password: pass
    ```

**客户端**

=== "命令行"

    ```bash
    gost -L :8080 -F relay+ssh://user:pass@:2222
    ```
	  或

    ```bash
    gost -L tcp://:8080/:80 -F sshd://user:pass@:2222
    ```

=== "配置文件(YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: auto
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :2222
          connector:
            type: relay
          dialer:
            type: ssh
            auth:
              username: user
              password: pass
    ```

### PubKey认证

**服务端**

服务端通过`authorizedKeys`选项设置已授权客户端公钥列表。

=== "命令行"

    ```bash
    gost -L "relay+ssh://:2222?authorizedKeys=/path/to/authorizedKeys"
    ```
	或

    ```bash
    gost -L "sshd://:2222?authorizedKeys=/path/to/authorizedKeys"
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: relay
      listener:
        type: ssh
        metadata:
          authorizedKeys: /path/to/authorizedKeys
    ```

**客户端**

客户端通过`privateKeyFile`和`passphrase`选项设置证书私钥和私钥密码。

=== "命令行"

    ```bash
    gost -L :8080 -F "relay+ssh://:2222?privateKeyFile=/path/to/privateKeyFile&passphrase=123456"
    ```
	  或

    ```bash
    gost -L tcp://:8080/:80 -F "sshd://:2222?privateKeyFile=/path/to/privateKeyFile&passphrase=123456"
    ```

=== "配置文件(YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: auto
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :2222
          connector:
            type: relay
          dialer:
            type: ssh
			metadata:
			  privateKeyFile: /path/to/privateKeyFile
			  passphrase: "123456"
    ```

## 心跳

客户端通过`keepalive`选项开启心跳，并通过`ttl`选项设置心跳包发送的间隔时长(默认30s)。

也可以通过`keepalive.timeout`选项设置心跳超时时长(默认15s)，`keepalive.retries`选项设置心跳发送重试次数(默认1次)

=== "命令行"

    ```bash
    gost -L :8080 -F "relay+ssh://:2222?keepalive=true&ttl=30s"
    ```
	  或

    ```bash
    gost -L tcp://:8080/:80 -F "sshd://:2222?keepalive=true&ttl=30s"
    ```

=== "配置文件(YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: auto
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :2222
          connector:
            type: relay
          dialer:
            type: ssh
			metadata:
			  keepalive: true
			  ttl: 30s
			  keepalive.timeout: 15s
			  keepalive.retries: 1
    ```

## 组合使用

SSH数据通道的隧道模式可以与各种代理协议组合使用。

### HTTP Over SSH

=== "命令行"

    ```bash
    gost -L http+ssh://:2222
    ```

=== "配置文件(YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: http
      listener:
        type: ssh
    ```

### SOCKS5 Over SSH

=== "命令行"

    ```bash
    gost -L socks5+ssh://:2222
    ```

=== "配置文件(YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: socks5
      listener:
        type: ssh
    ```

### Relay Over SSH

=== "命令行"

    ```bash
    gost -L relay+ssh://:2222
    ```

=== "配置文件(YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: ssh
    ```

## 端口转发

SSH通道的隧道模式也可以用作端口转发。

**服务端**

=== "命令行"

    ```bash
    gost -L ssh://:2222/:1080 -L socks5://:1080
    ```
	  等同于

    ```bash
    gost -L forward+ssh://:2222/:1080 -L socks5://:1080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: forward
      listener:
        type: ssh
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

通过使用SSH数据通道的端口转发，给1080端口的SOCKS5代理服务增加了SSH数据通道。

此时2222端口等同于：

```bash
gost -L socks5+ssh://:2222
```
