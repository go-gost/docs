---
comments: true
---

# 网络命名空间

!!! note "系统限制"
    网络命名空间仅支持Linux系统。

在Linux下可以通过[命名空间(Namespace)](https://en.wikipedia.org/wiki/Linux_namespaces)来对系统资源进行划分和隔离，其中的[网络命名空间(Network Namespace)](https://lwn.net/Articles/580893/)是实现网络虚拟化的重要手段。GOST可以对服务和转发节点分别设置不同的网络命名空间，从而提供在不同的虚拟网络中数据互通的功能。

## 创建和配置网络命名空间

通过`ip`命令可以管理网络命名空间:

```sh
# 创建网络命名空间ns1
ip netns add ns1
# 创建veth pair veth0和veth1并将veth1移到ns1中
ip link add dev veth0 type veth peer name veth1 netns ns1
# 配置veth0接口的IP地址为10.0.0.11
ip addr add 10.0.0.11/24 dev veth0
# 启用veth0接口
ip link set dev veth0 up
# 配置ns1中veth1接口的IP地址为10.0.0.1
ip -n ns1 addr add 10.0.0.1/24 dev veth1
# 启用ns1中的lo接口
ip -n ns1 link set dev lo up
# 启用ns1中veth1接口
ip -n ns1 link set dev veth1 up
```

以上命令创建了一个网络命名空间`ns1`，并且为其配置了一个veth类型的网络接口`veth1`与当前默认网络空间中的`veth0`相连。

通过`ip -n ns1 addr`可以查看到`ns1`中的网络状况:

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: veth1@if33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether b2:fd:33:f4:51:80 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.0.0.1/24 scope global veth1
       valid_lft forever preferred_lft forever
    inet6 fe80::b0fd:33ff:fef4:5180/64 scope link 
       valid_lft forever preferred_lft forever
```

用同样的方法创建网络命名空间`ns2`:

```sh
# 创建网络命名空间ns2
ip netns add ns2
# 创建veth pair veth2和veth3并将veth3移到ns2中
ip link add dev veth2 type veth peer name veth3 netns ns2
# 配置veth2接口的IP地址为10.0.1.11
ip addr add 10.0.1.11/24 dev veth2
# 启用veth2接口
ip link set dev veth2 up
# 配置ns2中veth3接口的IP地址为10.0.1.1
ip -n ns2 addr add 10.0.1.1/24 dev veth3
# 启用ns2中的lo接口
ip -n ns2 link set dev lo up
# 启用ns2中veth3接口
ip -n ns2 link set dev veth3 up
```

通过`ip -n ns2 addr`可以查看到`ns2`中的网络状况:

```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: veth3@if34: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 32:18:f0:6e:57:b3 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.0.1.1/24 scope global veth3
       valid_lft forever preferred_lft forever
    inet6 fe80::3018:f0ff:fe6e:57b3/64 scope link 
       valid_lft forever preferred_lft forever
```

## 使用网络命名空间

GOST中的网络命名空间有以下几种用法：

### 监听和转发在不同的命名空间

=== "命令行"

    ```bash
    gost -L tcp://10.0.0.1:8000/:8000?netns=ns1
    ```

=== "配置文件"

    ```yaml hl_lines="13"
    services:
    - name: service-0
      addr: 10.0.0.1:8000
      handler:
        type: tcp
      listener:
        type: tcp
      forwarder:
        nodes:
        - name: target-0
          addr: :8080
      metadata:
        netns: ns1
    ```

服务`service-0`的8000端口监听在网络命名空间`ns1`中，当与:8000节点建立连接时是在默认网络命名空间中，相当于在网络命名空间`ns1`中通过8000端口可以访问到默认命名空间的8000端口服务。

也可以通过`netns.out`选项指定转发所在的命名空间：

=== "命令行"

    ```bash
    gost -L "tcp://10.0.0.1:8000/10.0.1.1:8000?netns=ns1&netns.out=ns2"
    ```

=== "配置文件"

    ```yaml hl_lines="13"
    services:
    - name: service-0
      addr: 10.0.0.1:8000
      handler:
        type: tcp
      listener:
        type: tcp
      forwarder:
        nodes:
        - name: target-0
          addr: 10.0.1.1:8000
      metadata:
        netns: ns1
        netns.out: ns2
    ```

将`ns1`中的8000端口映射到`ns2`中的8000端口。

### 使用转发链

=== "命令行"

    ```bash
    gost -L tcp://10.0.0.1:8000/10.0.1.11:8000?netns=ns1 -F http://10.0.1.1:8080?netns=ns2
    ```

=== "配置文件"

    ```yaml hl_lines="14 20"
    services:
    - name: service-0
      addr: "10.0.0.1:8000"
      handler:
        type: tcp
        chain: chain-0
      listener:
        type: tcp
      forwarder:
        nodes:
        - name: target-0
          addr: 10.0.1.11:8000
      metadata:
        netns: ns1
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        metadata:
          netns: ns2
        nodes:
        - name: node-0
          addr: 10.0.1.1:8080
          connector:
            type: http
          dialer:
            type: tcp
    ```

监听在`ns1`命名空间的10.0.0.1:8000端口，通过`ns2`命名空间的10.0.1.1:8080代理服务转发到默认命名空间中的10.0.1.11:8000服务。