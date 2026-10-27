# TLS

名称: `tls`

状态： Stable

TLS拨号器使用TLS协议建立数据通道。

=== "命令行"
    ```
	gost -L :8080 -F http+tls://:8443
	```
=== "配置文件"
    ```yaml
    services:
   	- name: service-0
      addr: ":8080"
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
          addr: :8443
          connector:
            type: http
          dialer:
            type: tls
    ```

## 参数列表

`ech` (bool, default=false)
:    开启客户端 Encrypted Client Hello

`ech.doh` (string)
:    ECHConfigList 的获取端点（DoH URL），开启 ech 时必填

`ech.timeout` (duration, default=5s)
:    DoH 请求超时

`ech.ttl` (duration)
:    ECHConfigList 缓存时长；缺省使用 HTTPS RR 的 TTL

`ech.fallback` (bool, default=false)
:    DoH 失败或被拒收时降级为普通 TLS

`ech.dohInsecure` (bool, default=false)
:    跳过 DoH 证书校验

TLS配置请参考[TLS配置说明](/tutorials/tls/)。