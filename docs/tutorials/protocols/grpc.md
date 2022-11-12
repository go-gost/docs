# gRPC

gRPC是GOST中的一种数据通道类型。

!!! tip "TLS证书配置"
    TLS配置请参考[TLS配置说明](/tutorials/tls/)。

## 使用TLS

gRPC通道默认采用TLS加密。

=== "命令行"

    ```
	gost -L http+grpc://:8443
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
		type: grpc
	```

## 不使用TLS

通过`grpcInsecure`选项开启明文gRPC传输，不是TLS。

=== "命令行"

    ```bash
	gost -L http+grpc://:8443?grpcInsecure=true
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: http
	  listener:
		type: grpc
		metadata:
		  grpcInsecure: true
	```

## 自定义请求主机名

客户端默认使用节点地址(-F参数或nodes.addr中指定的地址)作为请求主机名(`:authority`头部信息)，可以通过`host`参数自定义请求主机名。

=== "命令行"

    ```bash
    gost -L http://:8080 -F grpc://:8443?host=example.com
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8443
          connector:
            type: http
          dialer:
            type: grpc
            metadata:
              host: example.com
    ```

## 自定义请求路径

可以通过`path`选项自定义请求路径，默认值为`/GostTunel/Tunnel`。

!!! note "路径匹配验证“
    仅当客户端和服务端设定的path参数相同时，连接才能成功建立。

### 服务端

=== "命令行"

    ```bash
    gost -L grpc://:8443?path=/GostTunel/Tunnel
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: auto
      listener:
        type: grpc
		metadata:
		  path: /GostTunel/Tunnel
    ```

### 客户端

=== "命令行"

    ```bash
    gost -L http://:8080 -F grpc://:8443?path=/GostTunel/Tunnel
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8443
          connector:
            type: http
          dialer:
            type: grpc
            metadata:
              path: /GostTunel/Tunnel
    ```

## 代理协议

gRPC数据通道可以与各种代理协议组合使用。

### HTTP Over gRPC

=== "命令行"

    ```bash
    gost -L http+grpc://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: grpc
    ```

### SOCKS5 Over gRPC

=== "命令行"

    ```bash
    gost -L socks5+grpc://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: grpc
    ```

### SS Over gRPC

=== "命令行"

    ```bash
    gost -L ss+grpc://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: ss
      listener:
        type: grpc
    ```

## 端口转发

gRPC通道也可以用作端口转发。

### 服务端

=== "命令行"

    ```bash
    gost -L grpc://:8443/:1080 -L socks5://:1080
    ```
	等同于
    ```bash
    gost -L forward+grpc://:8443/:1080 -L socks5://:1080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: grpc
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

通过使用gRPC数据通道的端口转发，给1080端口的SOCKS5代理服务增加了gRPC数据通道。

此时8443端口等同于：

```bash
gost -L socks5+gRPC://:8443
```
