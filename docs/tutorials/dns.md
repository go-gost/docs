# DNS代理

与域名解析器类似，DNS代理服务支持多种协议类型，支持自定义域名解析(映射器)，具有缓存功能，并支持转发链。

=== "命令行"

    ```bash
	gost -L dns://:10053/1.1.1.1,tls://1.1.1.1:853?mode=udp
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      handler:
        type: dns
		# chain: chain-0
      listener:
        type: dns
        metadata:
          mode: udp
      forwarder:
        nodes:
        - name: target-0
          addr: 1.1.1.1
        - name: target-1
          addr: tls://1.1.1.1:853
    ```

`mode` (string, default=udp)
:    DNS代理模式

    * `udp` - UDP模式(DNS over UDP)
	* `tcp` - TCP模式(DNS over TCP)
	* `tls` - TLS模式(DNS over TLS)
	* `https` - HTTPS模式(DNS over HTTPS)


每个上级DNS服务的格式为：`[protocol://]ip[:port]`。

 `protocol`支持的类型有udp，tcp，tls，https。默认值为udp。

 `port`默认值为53。

 例如：
 
 * udp://1.1.1.1:53，或udp://1.1.1.1
 * tcp://1.1.1.1:53
 * tls://1.1.1.1:853
 * https://1.0.0.1/dns-query

## 自定义域名解析

通过设置主机IP映射器，可以对域名进行自定义解析。

=== "命令行"

    ```
    gost -L dns://:10053/1.1.1.1?hosts=example.org:127.0.0.1,example.org:::1,example.com:2001:db8::1
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      hosts: hosts-0
      handler:
        type: dns
      listener:
        type: dns
        metadata:
          mode: udp
      forwarder:
        nodes:
        - name: target-0
          addr: 1.1.1.1
    hosts:
    - name: hosts-0
      mappings:
      - ip: 127.0.0.1
        hostname: example.org
      - ip: ::1
        hostname: example.org
      - ip: 2001:db8::1
        hostname: example.com
    ```

此时解析example.org会匹配到映射器而不会使用1.1.1.1查询。

!!! example "DNS查询example.org(ipv4)"

	```bash
	dig -p 10053 example.org
	```

	```
	;; QUESTION SECTION:
    ;example.org.				IN	A

    ;; ANSWER SECTION:
    example.org.		3600	IN	A	127.0.0.1
	```

!!! example "DNS查询example.org(ipv6)"

	```bash
	dig -p 10053 AAAA example.org
	```

	```
	;; QUESTION SECTION:
    ;example.org.				IN	AAAA

    ;; ANSWER SECTION:
    example.org.		3600	IN	AAAA	::1
	```

解析example.com时，由于ipv4在映射器中无对应项，因此会使用1.1.1.1进行解析。

!!! example "DNS查询example.com(ipv4)"

	```bash
	dig -p 10053 example.com
	```

	```
	;; QUESTION SECTION:
    ;example.com.				IN	A

    ;; ANSWER SECTION:
    example.com.		10610	IN	A	93.184.216.34
	```

!!! example "DNS查询example.com(ipv6)"

	```bash
	dig -p 10053 AAAA example.com
	```

	```
	;; QUESTION SECTION:
    ;example.com.				IN	AAAA

    ;; ANSWER SECTION:
    example.com.		3600	IN	AAAA	2001:db8::1
	```

## 分流

通过在DNS代理服务上和转发器的节点上设置分流器可以实现对DNS查询的分流。

### 服务上的分流器

当DNS代理服务本身设置了分流器，如果DNS查询的域名未通过分流器规则测试(未匹配白名单规则或匹配黑名单规则)，则DNS代理服务返回空结果。

=== "命令行"

    ```bash
	gost -L dns://:10053/1.1.1.1?bypass=example.com
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      bypass: bypass-0
      handler:
        type: dns
      listener:
        type: dns
      forwarder:
        nodes:
        - name: target-0
          addr: 1.1.1.1
    bypasses:
    - name: bypass-0
      matchers:
      - example.com
    ```

当查询`example.com`时，未通过服务上的分流器bypass-0，查询将返回空结果。

!!! example "DNS查询example.com(ipv4)"

	```bash
	dig -p 10053 example.com
	```

	```
	;; QUESTION SECTION:
    ;example.com.				IN	A
	```

当查询`example.org`时，通过服务上的分流器bypass-0，查询将正常返回结果。

!!! example "DNS查询example.org(ipv4)"

	```bash
	dig -p 10053 example.org
	```

	```
	;; QUESTION SECTION:
    ;example.org.				IN	A

    ;; ANSWER SECTION:
    example.org.		74244	IN	A	93.184.216.34
	```

### 目标节点上的分流器

类似于转发链节点上的分流器，DNS代理服务的转发器节点上也可以通过设置转发器来实现精细化分流。

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      handler:
        type: dns
      listener:
        type: dns
      forwarder:
        nodes:
        - name: target-0
          addr: 1.1.1.1
          bypass: bypass-0
        - name: target-1
          addr: 8.8.8.8
          bypass: bypass-1
    bypasses:
    - name: bypass-0
      matchers:
      - example.org
    - name: bypass-1
      matchers:
      - example.com
    ```

当查询`example.org`时，未通过目标节点target-0上的分流器bypass-0，通过了目标节点target-1的分流器bypass-1，查询将转发给节点target-1进行处理。

当查询`example.com`时，通过目标节点target-0上的分流器bypass-0，未通过目标节点target-1的分流器bypass-1，查询将转发给节点target-0进行处理。

## 缓存

通过`ttl`参数可以设置缓存时长，默认使用DNS查询返回结果中的TTL，当设置为负值，则不使用缓存。

=== "命令行"
    ```
	gost -L dns://:10053?dns=1.1.1.1&ttl=60s
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      handler:
        type: dns
        metadata:
          dns:
          - 1.1.1.1
		  ttl: 60s
      listener:
        type: dns
    ```

## ECS

通过`clientIP`参数设置客户端IP，开启ECS(EDNS Client Subnet)扩展功能。

=== "命令行"
    ```
	gost -L dns://:10053?dns=1.1.1.1&clientIP=1.2.3.4
    ```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      handler:
        type: dns
        metadata:
          dns:
          - 1.1.1.1
		  clientIP: 1.2.3.4
      listener:
        type: dns
    ```