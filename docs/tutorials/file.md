---
comments: true
---

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

`put` (bool, default=false) :material-tag: 3.3.0
:    启用HTTP PUT上传支持。开启后可通过PUT请求上传文件到服务器。

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

## 文件上传

:material-tag: 3.3.0

当开启`put`选项后，文件服务支持通过HTTP PUT方法上传文件。

=== "命令行"

    ```bash
    gost -L "file://:8080?dir=/path/to/dir&put=true"
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
          put: true
      listener:
        type: tcp
    ```

上传文件：

```bash
curl -X PUT -T ./local-file.txt http://localhost:8080/remote-file.txt
```

## 公网临时访问

如果需要临时通过公网来访问文件服务，可以通过 [Wisper](https://wisper.gost.run) 提供的公共反向代理服务将本地文件服务匿名暴露到公网来访问。

```sh
gost -L file://:8080 -L rtcp://:0/:8080 -F tunnel+wss://wisper.gost.run:443
```

当正常连接到Wisper服务后，会有类似如下日志信息：

```json
{"connector":"tunnel","dialer":"wss","endpoint":"006478add9ed096a","hop":"hop-0","kind":"connector","level":"info",
"msg":"create tunnel on 006478add9ed096a:0/tcp OK, tunnel=50ce9728-5d92-4d45-871d-4f275d5179cb, connector=956fcbe5-6e2d-439a-8aa3-af0df848a81a",
"node":"node-0","time":"2023-10-19T22:41:05.759+08:00",
"tunnel":"50ce9728-5d92-4d45-871d-4f275d5179cb"}
```

日志的`endpoint`信息中`006478add9ed096a`是为此服务生成的临时公共访问点，有效期为24小时。通过[https://006478add9ed096a.gost.run](https://006478add9ed096a.gost.run)便能立即访问到此文件服务。