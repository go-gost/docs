# DNS Proxy

Similar to the domain name resolver, the DNS proxy service supports multiple protocol types, supports custom domain name resolution (host mapper), has a caching function, and supports forwarding chains.

=== "CLI"
    ```
	gost -L dns://:10053?mode=udp&dns=1.1.1.1,tls://1.1.1.1:853
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      handler:
        type: dns
		# chain: chain-0
        metadata:
          dns:
          - 8.8.8.8
          - tls://1.1.1.1:853
      listener:
        type: dns
        metadata:
          mode: udp
    ```

`mode` (string, default=udp)
:    Proxy mode

    * `udp` - DNS over UDP
	* `tcp` - DNS over TCP
	* `tls` - DNS over TLS
	* `https` - DNS over HTTPS

`dns` (string, default=127.0.0.1:53)
:    List of upstream DNS

     The format of each DNS is: `[protocol://]ip[:port]`.

	 `protocol`: udp, tcp, tls and https. Default value is udp.

	 `port`: default value is 53.

	 Examples:
	 
	 * udp://1.1.1.1:53, or udp://1.1.1.1
	 * tcp://1.1.1.1:53
	 * tls://1.1.1.1:853
	 * https://1.0.0.1/dns-query

## Custom domain name resolution

Domain name resolution can be customized by setting the host-IP mapper.

```
gost -L dns://:10053?dns=1.1.1.1&hosts=example.org:127.0.0.1,example.org:::1,example.com:2001:db8::1
```

Then parsing `example.org` will match the mapper without using the 1.1.1.1 query.

!!! example "DNS Query example.org(ipv4)"
	```
	dig -p 10053 example.org
	```

	```
	;; QUESTION SECTION:
    ;example.org.				IN	A

    ;; ANSWER SECTION:
    example.org.		3600	IN	A	127.0.0.1
	```

!!! example "DNS Query example.org(ipv6)"
	```
	dig -p 10053 AAAA example.org
	```

	```
	;; QUESTION SECTION:
    ;example.org.				IN	AAAA

    ;; ANSWER SECTION:
    example.org.		3600	IN	AAAA	::1
	```

When parsing `example.com`, since ipv4 has no counterpart in the mapper, 1.1.1.1 is used for parsing.

!!! example "DNS Query example.com(ipv4)"
	```
	dig -p 10053 example.com
	```

	```
	;; QUESTION SECTION:
    ;example.com.				IN	A

    ;; ANSWER SECTION:
    example.com.		10610	IN	A	93.184.216.34
	```

!!! example "DNS Query example.com(ipv6)"
	```
	dig -p 10053 AAAA example.com
	```

	```
	;; QUESTION SECTION:
    ;example.com.				IN	AAAA

    ;; ANSWER SECTION:
    example.com.		3600	IN	AAAA	2001:db8::1
	```

## Cache

The cache duration can be set through the `ttl` parameter. By default, the TTL in the result returned by the DNS query is used. When it is set to a negative value, the cache is not used.

=== "CLI"
    ```
	gost -L dns://:10053?dns=1.1.1.1&ttl=60s
    ```

=== "File (YAML)"

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

Set the client IP through the `clientIP` parameter, and enable the ECS (EDNS Client Subnet) extension function.

=== "CLI"
    ```
	gost -L dns://:10053?dns=1.1.1.1&clientIP=1.2.3.4
    ```

=== "File (YAML)"

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