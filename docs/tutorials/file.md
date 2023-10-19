# HTTP文件服务

HTTP文件服务，将本地的文件系统目录转成HTTP服务。

## 使用方法

=== "命令行"

    ```bash
    gost -L file://:8080?dir=/path/to/dir
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: file
        metadata:
          dir: /path/to/dir
      listener:
        type: tcp
    ```

`dir` (string):
:    文件目录，默认为当前工作目录。

!!! note "转发链"
    文件服务会忽略转发链。
    
## 示例

### 简单的HTTP文件服务

将`/home`以HTTP服务的方式暴露在8080端口。

=== "命令行"

    ```bash
    gost -L file://:8080?dir=/home
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: file
        metadata:
          dir: /home
      listener:
        type: tcp
    ```

### 认证

为服务设置基本认证。

=== "命令行"

    ```bash
    gost -L file://user:pass@:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: file
        auth:
          username: user
          password: pass
      listener:
        type: tcp
    ```

### TLS

为服务增加TLS加密传输层(HTTPS)。


=== "命令行"

    ```bash
    gost -L file+tls://:8443
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: file
      listener:
        type: tls
    ```

## 公网临时访问

如果需要临时通过公网来访问文件服务，可以通过`GOST.PLUS`提供的公共反向代理服务将本地文件服务匿名暴露到公网来访问。

```sh
gost -L file://:8080 -L rtcp://:0/:8080 -F tunnel+wss://tunnel.gost.plus:443?tunnel.id=50ce9728-5d92-4d45-871d-4f275d5179cb
```

当正常连接到`gost.plus`服务后，会有类似如下日志信息：

```json
{"connector":"tunnel","dialer":"wss","hop":"hop-0","kind":"connector","level":"info",
"msg":"create tunnel on 006478add9ed096a:0/tcp OK, tunnel=50ce9728-5d92-4d45-871d-4f275d5179cb, connector=956fcbe5-6e2d-439a-8aa3-af0df848a81a",
"node":"node-0","time":"2023-10-19T22:41:05.759+08:00"}
```

日志的`msg`信息中`006478add9ed096a`是为此服务生成的临时公共访问点，有效期为1小时。通过[https://006478add9ed096a.gost.plus](https://006478add9ed096a.gost.plus)便能立即访问到此文件服务。

!!! note "tunnel.id"
    `tunnel.id`参数指定隧道ID，参数值为合法的UUID。为了避免隧道ID冲突，推荐使用UUID生成工具生成随机UUID。