# KCP

名称: `kcp`

状态： GA

KCP监听器根据服务配置，监听在指定UDP端口，并使用[KCP协议](https://github.com/xtaci/kcptun)进行通讯。

=== "命令行"
    ```
    gost -L http+kcp://:8443
    ```
=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: ":8443"
      handler:
        type: http
      listener:
        type: kcp
        metadata:
          config:
            crypt: aes
            mode: fast
            mtu: 1350
    ```

## 参数列表

`backlog` (int, default=128)
:    单个连接的数据流队大小

`config` (object)
:    KCP配置

`c` (string)
:    KCP配置JSON文件

## KCP配置

```yaml
config
  key: "it's a secrect"
  crypt: "aes"
  mode: "fast"
  mtu: 1350
  sndwnd: 1024
  rcvwnd: 1024
  datashard: 10
  parityshard: 3
  dscp: 0
  nocomp: false
  acknodelay: false
  nodelay: 0
  interval: 50
  resend: 0
  nc: 0
  sockbuf: 4194304
  smuxbuf: 4194304
  streambuf: 2097152
  smuxver: 1
  keepalive: 10
  snmplog: ""
  snmpperiod: 60
  signal: false
  tcp: false
```

配置文件中的参数说明请参考[kcptun](https://github.com/xtaci/kcptun#usage)。