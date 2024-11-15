---
comments: true
---

# 服务

!!! tip "动态配置"
    服务支持通过[Web API](../tutorials/api/overview.md)进行动态配置。

!!! tip "一切皆服务"
    在GOST中客户端和服务端是相对的，客户端本身也是一个服务，如果使用了转发链或转发器，则其中的节点就被当作服务端。

服务是GOST的基础模块，是GOST程序的入口，无论是服务端还是客户端都是以服务为基础构建。
一个服务包括一个监听器作为数据通道，一个处理器用于数据处理和一个可选的转发器用于端口转发。

=== "命令行"

    ```sh
    gost -L http://:8080
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: http
      listener:
        type: tcp
    ```

## 流程

当一个服务运行后，监听器会根据服务的配置监听在指定的端口并使用指定的协议进行通讯。收到正确的数据后，监听器建立一个数据通道连接，将此连接交给处理器使用。处理器按照指定的协议进行数据通讯，收到客户端的请求后，获取到目标地址，如果使用了转发器，则使用转发器中指定的目标地址，再使用路由器将请求发送到此目标主机。

!!! info "路由器"
	路由器是处理器内部的一个抽象模块，其内部包含了转发链，域名解析器，主机映射器等，用于服务和目标主机之间的请求路由。

## 忽略转发链

在命令行模式下，如果有转发链，则默认所有服务均会使用此转发链。通过`ignoreChain`选项可以让特定的服务不使用转发链。

```bash
gost -L http://:8080?ignoreChain=true -L socks://:1080 -F http://:8000
```

8080端口的HTTP服务不使用转发链，1080端口的SOCKS5服务使用转发链。

## 多进程

命令行模式下默认所有服务在同一个进程中运行，通过`--`分割符让服务在单独的进程中运行。

```bash
gost -L http://:8080 -- -L http://:8000 -- -L socks://:1080 -F http://:8000
```

以上命令会将启动三个进程分别对应三个服务，其中的转发链仅由1080端口的服务使用。

## 执行命令(Linux)

在Linux下，通过`preUp`，`postUp`，`preDown`，`postDown`选项可以在服务启动或停止前后执行额外的命令。

```yaml
services:
- name: service-0
  addr: :8080
  metadata:
    preUp:
    - echo pre-up
    postUp:
    - echo post-up
    preDown:
    - echo pre-down
    postDown:
    - echo post-down
  handler:
    type: http
  listener:
    type: tcp
```