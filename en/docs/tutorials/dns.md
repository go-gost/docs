# DNS Proxy

Similar to the domain name resolver, the DNS proxy service supports multiple protocol types, supports custom domain name resolution (host mapper), has a caching function, and supports forwarding chains.

=== "CLI"
    ```
    gost -L dns://:10053/1.1.1.1,tls://1.1.1.1:853?mode=udp
    ```

=== "File (YAML)"

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
:    Proxy mode

    * `udp` - DNS over UDP
    * `tcp` - DNS over TCP
    * `tls` - DNS over TLS
    * `https` - DNS over HTTPS


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

=== "CLI"

```
gost -L dns://:10053/1.1.1.1?hosts=example.org:127.0.0.1,example.org:::1,example.com:2001:db8::1
```

=== "File (YAML)"

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

Then query for `example.org` will match the mapper without using the 1.1.1.1.

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

When querying for `example.com`, since ipv4 has no counterpart in the mapper, 1.1.1.1 is used.

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

## Bypass

The DNS queries can be fine-grained devided by setting bypasses on the DNS proxy service and the forwarder nodes.


### Service Level Bypass

When the DNS proxy service itself is set with a bypass, if the domain name queries does not pass the rule test (does not match the whitelist or matches the blacklist), the DNS proxy service returns an empty result.

=== "CLI"

    ```bash
	gost -L dns://:10053/1.1.1.1?bypass=example.com
    ```

=== "File (YAML)"

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

When querying `example.com`, the bypass-0 on the service is not passed, and the query will return empty results.

!!! example "DNS Query example.com(ipv4)"

	```bash
	dig -p 10053 example.com
	```

	```
	;; QUESTION SECTION:
    ;example.com.				IN	A
	```

When querying `example.org`, it passes the bypass bypass-0 on the service, the query will return results normally.

!!! example "DNS Query example.org(ipv4)"

	```bash
	dig -p 10053 example.org
	```

	```
	;; QUESTION SECTION:
    ;example.org.				IN	A

    ;; ANSWER SECTION:
    example.org.		74244	IN	A	93.184.216.34
	```

### Bypass On Forwarder Nodes

Similar to the bypass on the forwarding chain node, the forwarder nodes of the DNS proxy service can also be set to achieve fine-grained query control.

=== "File (YAML)"

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

When querying `example.org`, it does not pass the bypass bypass-0 on the target node target-0, but passes the bypass bypass-1 on the target node target-1, and the query will be forwarded to the node target-1 for processing.

When querying `example.com`, it passes the bypass bypass-0 on the target node target-0, but does not pass the bypass bypass-1 on the target node target-1, the query will be forwarded to the node target-0 for processing.

## Cache

The cache duration can be set through the `ttl` option. By default, the TTL in the result returned by the DNS query is used. When it is set to a negative value, the cache is not used.

=== "CLI"
    ```
    gost -L dns://:10053/1.1.1.1?ttl=60s
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      handler:
        type: dns
        metadata:
          ttl: 60s
      listener:
        type: dns
      forwarder:
        nodes:
        - name: target-0
          addr: 1.1.1.1
    ```

## Asynchronous Query

Use the `async` option to set the query request to the upper-level DNS service to be asynchronous. At this time, when the cache is expired, the result in the client cache will still be returned, and at the same time, the query request will be sent to the upper-level DNS proxy service asynchronously and the cache will be updated.

=== "CLI"
    ```
    gost -L dns://:10053/1.1.1.1?async=true
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      handler:
        type: dns
        metadata:
          async: true
      listener:
        type: dns
      forwarder:
        nodes:
        - name: target-0
          addr: 1.1.1.1
    ```

## ECS

Set the client IP through the `clientIP` option, and enable the ECS (EDNS Client Subnet) extension function.

=== "CLI"
    ```
    gost -L dns://:10053/1.1.1.1?clientIP=1.2.3.4
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      handler:
        type: dns
        metadata:
          clientIP: 1.2.3.4
      listener:
        type: dns
      forwarder:
        nodes:
        - name: target-0
          addr: 1.1.1.1
    ```