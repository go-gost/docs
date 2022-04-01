# 透明代理

透明代理支持REDIRECT和TPROXY两种方式，REDIRECT方式仅支持TCP。

!!! note "系统限制"
    透明代理仅支持Linux系统。

!!! note "流量嗅探"
    TCP透明代理支持对HTTP和TLS流量进行识别，识别后将使用HTTP`Host`头部信息或TLS的`SNI`扩展信息作为目标访问地址。

    通过`sniffing`参数开启流量嗅探，默认不开启。

## REDIRECT

采用REDIRECT方式的透明代理可以选择给数据包打标记(Mark)。使用Mark需要管理员权限运行。

### 不使用Mark

=== "命令行"
    ```
    gost -L red://:12345?sniffing=true -F 192.168.1.1:1080
    ```
=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: :12345
      handler:
        type: red
        chain: chain-0
        metadata:
          sniffing: true
      listener:
        type: red
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: 192.168.1.1:1080
          connector:
            type: http
          dialer:
            type: tcp
    ```


!!! example "iptables-本地全局TCP代理"
    ```
    iptables -t nat -A OUTPUT -p tcp --match multiport ! --dports 12345,1080 -j DNAT --to-destination 127.0.0.1:12345
    ```

### 使用Mark

使用Mark可以避免出口流量被二次拦截造成死循环。

=== "命令行"
    ```
    gost -L "red://:12345?sniffing=true&so_mark=100"
    ```
=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: :12345
      sockopts:
        mark: 100
      handler:
        type: red
        metadata:
          sniffing: true
      listener:
        type: red
    ```

#### 使用转发链

=== "命令行"
    ```
    gost -L red://:12345?sniffing=true -F "http://192.168.1.1:1080?so_mark=100"
    ```
=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: :12345
      handler:
        type: red
        chain: chain-0
        metadata:
          sniffing: true
      listener:
        type: red
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        sockopts:
          mark: 100  
        nodes:
        - name: node-0
          addr: 192.168.1.1:1080
          # node level sockopts, will override hop level value.
          # sockopts:
          #   mark: 100  
          connector:
            type: http
          dialer:
            type: tcp
    ```

通过`so_mark`(命令行)或`sockopts`(配置文件)参数来设置mark值。

!!! example "iptables规则"
    ```
    iptables -t nat -N GOST
    # 忽略局域网流量，请根据实际网络环境进行调整
    iptables -t nat -A GOST -d 192.168.0.0/16 -j RETURN
    # 忽略出口流量
    iptables -t nat -A GOST -p tcp -m mark --mark 100 -j RETURN
    # 重定向TCP流量到12345端口
    iptables -t nat -A GOST -p tcp -j REDIRECT --to-ports 12345
    # 拦截局域网流量
    iptables -t nat -A PREROUTING -p tcp -j GOST
    # 拦截本机流量
    iptables -t nat -A OUTPUT -p tcp -j GOST
    ```

## TPROXY

### TCP

=== "命令行"
    ```
    gost -L "red://:12345?sniffing=true&tproxy=true&so_mark=100"
    ```
=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: :12345
      sockopts:
        mark: 100  
      handler:
        type: red
        metadata:
          sniffing: true
          tproxy: true
      listener:
        type: red
        metadata:
          tproxy: true
    ```

#### 使用转发链

=== "命令行"
    ```
    gost -L "red://:12345?sniffing=true&tproxy=true" -F http://192.168.1.1:8080?so_mark=100
    ```
=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: :12345
      handler:
        type: red
        chain: chain-0
        metadata:
          sniffing: true
          tproxy: true
      listener:
        type: red
        metadata:
          tproxy: true
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        sockopts:
          mark: 100  
        nodes:
        - name: node-0
          addr: 192.168.1.1:8080
          connector:
            type: http
          dialer:
            type: tcp
    ```

!!! example "routing和iptables规则"
    ```
    ip rule add fwmark 1 lookup 100
    ip route add local 0.0.0.0/0 dev lo table 100

    iptables -t mangle -N DIVERT
    iptables -t mangle -A DIVERT -j MARK --set-mark 1
    iptables -t mangle -A DIVERT -j ACCEPT
    iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT

    iptables -t mangle -N GOST
    iptables -t mangle -A GOST -p tcp -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A GOST -p tcp -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A GOST -p tcp -m mark --mark 100 -j RETURN 
    iptables -t mangle -A GOST -p tcp -j TPROXY --tproxy-mark 0x1/0x1 --on-ip 127.0.0.1 --on-port 12345 
    iptables -t mangle -A PREROUTING -p tcp -j GOST

    iptables -t mangle -N GOST_LOCAL
    iptables -t mangle -A GOST_LOCAL -p tcp -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p tcp -d 255.255.255.255/32 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p tcp -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p tcp -m mark --mark 100 -j RETURN 
    iptables -t mangle -A GOST_LOCAL -p tcp -j MARK --set-mark 1
    iptables -t mangle -A OUTPUT -p tcp -j GOST_LOCAL
    ```

### UDP

=== "命令行"
    ```
    gost -L "redu://:12345?ttl=30s&so_mark=100"
    ```
=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: :12345
      sockopts:
        mark: 100  
      handler:
        type: redu
      listener:
        type: redu
        metadata:
          ttl: 30s
    ```

#### 使用转发链

=== "命令行"
    ```
    gost -L redu://:12345?ttl=30s -F relay://192.168.1.1:8421?so_mark=100
    ```
=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: :12345
      handler:
        type: redu
        chain: chain-0
      listener:
        type: redu
        metadata:
          ttl: 30s
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        sockopts:
          mark: 100  
        nodes:
        - name: node-0
          addr: 192.168.1.1:8421
          connector:
            type: relay
          dialer:
            type: tcp
    ```

`ttl` (duration, default=30s)
:   传输通道超时时长。

!!! example "routing和iptables规则"
    ```
    ip rule add fwmark 1 lookup 100
    ip route add local 0.0.0.0/0 dev lo table 100

    iptables -t mangle -N GOST
    iptables -t mangle -A GOST -p udp -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A GOST -p udp -d 255.255.255.255/32 -j RETURN
    iptables -t mangle -A GOST -p udp -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A GOST -p udp -m mark --mark 100 -j RETURN 
    iptables -t mangle -A GOST -p udp -j TPROXY --tproxy-mark 0x1/0x1 --on-ip 127.0.0.1 --on-port 12345 
    iptables -t mangle -A PREROUTING -p udp -j GOST

    iptables -t mangle -N GOST_LOCAL
    iptables -t mangle -A GOST_LOCAL -p udp -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p udp -d 255.255.255.255/32 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p udp -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A GOST_LOCAL -p udp -m mark --mark 100 -j RETURN 
    iptables -t mangle -A GOST_LOCAL -p udp -j MARK --set-mark 1
    iptables -t mangle -A OUTPUT -p udp -j GOST_LOCAL
    ```