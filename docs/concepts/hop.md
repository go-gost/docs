# 跳跃点

!!! tip "动态配置"
    跳跃点在引用模式下支持通过[Web API](/tutorials/api/overview/)进行动态配置。

跳跃点是对转发链层级的抽象，是转发链的基本组成部分。一个跳跃点中包含一个或多个节点(Node)，和一个节点[选择器](/concepts/selector/)，在每次执行数据转发请求时，通过在转发链的每个跳跃点上使用选择器在节点组中选出一个节点，最终构成一条转发路径(Route)来处理请求。

跳跃点有两种使用方式：内联模式和引用模式。

## 内联模式

在转发链中可以直接定义跳跃点。

=== "命令行"

    ```
    gost -L http://:8080 -F https://192.168.1.1:8080 -F socks5+ws://192.168.1.2:1080
    ```

=== "配置文件"

    ```yaml hl_lines="12 20"
    services:
    - name: service-0
      addr: ":8080"
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
          addr: 192.168.1.1:8080
          connector:
            type: http
          dialer:
            type: tls
      - name: hop-1
        nodes:
        - name: node-0
          addr: 192.168.1.2:1080
          connector:
            type: socks5
          dialer:
            type: ws
    ```

以上配置中有一条转发链(chain-0)，其中有两个跳跃点(hop-0，hop-1)，每个跳跃点中有一个节点。

## 引用模式

也可以单独定义跳跃点再通过引用跳跃点的名称来使用特定的跳跃点。

```yaml hl_lines="13 14 17 25"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    chain: chain-0
  listener:
    type: tcp

chains:
- name: chain-0
  hops:
  - name: hop-0
  - name: hop-1

hops:
- name: hop-0
  nodes:
  - name: node-0
    addr: 192.168.1.1:8080
    connector:
      type: http
	dialer:
      type: tls
- name: hop-1
  nodes:
  - name: node-0
    addr: 192.168.1.2:1080
    connector:
      type: socks5
    dialer:
      type: ws
```

在chain中通过`name`来引用`hops`中定义的跳跃点。

### 转发器

转发器中同样也可以通过引用模式来使用跳跃点。

```yaml hl_lines="9"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: tcp 
  listener:
    type: tcp
  forwarder:
    name: hop-0

hops:
- name: hop-0
  nodes:
  - name: target-0
    addr: 192.168.1.1:8080
  - name: target-1
    addr: 192.168.1.2:8080
```

## 优先级

当使用内联模式时，如果跳跃点中未定义节点则会自动切换到引用模式。