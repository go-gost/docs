# 选择器

选择器负责在一个可选择的对象列表中使用选择策略选择出零个或一个对象，目前选择器所支持的对象有节点和转发链两种。
选择器可以应用于转发链组，转发链，转发链中的跳跃点，和转发器上。选择器在GOST中可以用来实现负载均衡。

`strategy` (string, default=round)
:    指定选择策略。
    
     * `round` - 轮询
     * `rand` - 随机
     * `fifo` - 自上而下，主备模式

`maxFails` (int, default=1)
:    指定最大失败次数，当失败次数超过此设定值时，此对象会被标记为失败(Fail)状态，失败状态的对象不会被选择使用。

`failTimeout` (duration, default=10s)
:    指定失败状态的超时时长，当一个对象被标记为失败后，在此设定的时间间隔内不会被选择使用，超过此设定时间间隔后，会再次参与选择。

## 转发链

转发链中的每一层级跳跃点上可以设置一个选择器，默认选择器使用轮询策略进行节点选择。

=== "命令行"
	```
	gost -L http://:8080 -F "socks5://192.168.1.1:1080,192.168.1.2:1080?strategy=rand&maxFails=1&failTimeout=10s"
	```
=== "配置文件"

    ```yaml hl_lines="13 14 15 16"
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
        selector:
          strategy: rand
          maxFails: 1
          failTimeout: 10s
        nodes:
        - name: node-0
          addr: 192.168.1.1:1080
          connector:
            type: socks5
          dialer:
            type: tcp
          metadata:
            maxFails: 2
            failTimeout: 20s
        - name: node-1
          addr: 192.168.1.2:1080
          connector:
            type: socks5
          dialer:
            type: tcp
          metadata:
            maxFails: 3
            failTimeout: 30s
	```

## 转发器

转发器用于端口转发，其本身由一个节点组和一个节点选择器组成，当进行转发时，通过选择器在节点组中选择出零个或一个节点用于转发的目标地址。此时转发器类似于只有一个层级的转发链。

=== "命令行"
    ```
	gost -L "tcp://:8080/:8081,:8082?strategy=round&maxFails=1&failTimeout=30s"
	```
=== "配置文件"

    ```yaml hl_lines="14 15 16 17"
    services:
    - name: service-0
      addr: :8080
      handler:
        type: tcp
      listener:
        type: tcp
      forwarder:
        nodes:
        - name: target-0
          addr: :8081
        - name: target-1
          addr: :8082
        selector:
          strategy: round
          maxFails: 1
          failTimeout: 30s
    ```

## 转发链组

转发链组中的选择器类似于转发器中的选择器，用来选择一条转发链。

```yaml hl_lines="10 11 12 13"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    chainGroup:
      chains:
      - chain-0
      - chain-1
      selector:
        strategy: round
        maxFails: 1
        failTimeout: 10s
  listener:
    type: tcp
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8081
      connector:
        type: http
      dialer:
        type: tcp
- name: chain-1
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8082
      connector:
        type: http
      dialer:
        type: tcp
```

## 备用节点和备用链

通过将一个或多个节点或转发链标记为备用状态，当所有非备用节点或转发链均被标记为失败状态时才会参与选择。

### 备用节点

```yaml hl_lines="20 21 22 35 36 43 44"
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
    selector:
      strategy: round
      maxFails: 1
      failTimeout: 10s
    nodes:
    - name: node-0
      addr: :8081
      metadata:
        maxFails: 3
        failTimeout: 30s
      connector:
        type: http
      dialer:
        type: tcp
    - name: node-1
      addr: :8082
      connector:
        type: http
      dialer:
        type: tcp
    - name: node-2
      addr: :8083
      metadata:
        backup: true
      connector:
        type: http
      dialer:
        type: tcp
    - name: node-3
      addr: :8084
      metadata:
        backup: true
      connector:
        type: http
      dialer:
        type: tcp
```

通过`metadata.backup`选项将节点标记为备用状态。

正常情况下只有node-0和node-1两个非备用节点参与节点选择，当node-0和node-1均被标记为失败状态时，node-2和node-3才会参与节点选择。当node-0和node-1中任何一个节点恢复后，node-2和node-3退出节点选择。

!!! tip "节点级别失败状态控制"
    注意这里的node-0节点，通过`metadata.maxFails`和`metadata.failTimeout`选项可以对此节点进行单独的失败状态控制，默认使用选择器中的对应参数。

### 备用转发链

```yaml hl_lines="40 41 52 53"
services:
- name: service-0
  addr: :8080
  handler:
    type: http
    chainGroup:
      chains:
      - chain-0
      - chain-1
      - chain-2
      - chain-3
      selector:
        strategy: round
        maxFails: 1
        failTimeout: 10s
  listener:
    type: tcp
chains:
- name: chain-0
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8081
      connector:
        type: http
      dialer:
        type: tcp
- name: chain-1
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8082
      connector:
        type: http
      dialer:
        type: tcp
- name: chain-2
  metadata:
    backup: true
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8083
      connector:
        type: http
      dialer:
        type: tcp
- name: chain-3
  metadata:
    backup: true
  hops:
  - name: hop-0
    nodes:
    - name: node-0
      addr: :8084
      connector:
        type: http
      dialer:
        type: tcp
```

与备用节点类似，通过`metadata.backup`选项将转发链chain-2和chain-3标记为备用状态。

## 加权随机选择策略

选择器在随机选择策略基础上支持对节点和转发链设置权重，权重默认值为1。

```yaml hl_lines="20 21 28 29"
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
    selector:
      strategy: rand
      maxFails: 1
      failTimeout: 10s
    nodes:
    - name: node-0
      addr: :8081
      metadata:
        weight: 20 
      connector:
        type: http
      dialer:
        type: tcp
    - name: node-1
      addr: :8082
      metadata: 
        weight: 10
      connector:
        type: http
      dialer:
        type: tcp
```

通过`metadata.weight`选项对节点(转发链类似)设置权重。node-0与node-1权重比值为2:1，因此node-0被选中几率是node-1的两倍。