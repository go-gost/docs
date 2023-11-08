# Domain Name Resolution

!!! tip "Dynamic configuration"
    Resolver supports dynamic configuration via [Web API](/en/tutorials/api/overview/).

## Resolver

Resolver resolves the domain name by setting the upper-level DNS list, and the resolver can be applied to the service or forwarding chain. The resolver in the service resolves the target address of the request, and the resolver in the forwarding chain resolves the node addresses.

## Resolver In Service

Use Resolver to resolve the request target address.

=== "CLI"
	```
	gost -L http://:8080?resolver=1.1.1.1,tcp://8.8.8.8,tls://8.8.8.8:853,https://1.0.0.1/dns-query
	```

	Use the `resolver` option to specify the list of upper-level DNS.

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      resolver: resolver-0
      handler:
        type: http
      listener:
        type: tcp
	resolvers:
	- name: resolver-0
	  nameservers:
	  - addr: 1.1.1.1
	  - addr: tcp://8.8.8.8
	  - addr: tls://8.8.8.8:853
	  - addr: https://1.0.0.1/dns-query
	```

	The `resolver` property is used in the service to use the specified resolver by referencing the resolver name.

The format of each DNS is:

`[protocol://]ip[:port]`

* `protocol` types: `udp`, `tcp`, `tls`, `https`. Default value is `udp`.

* `port` default value is 53.

!!! example

    * udp://1.1.1.1:53，或udp://1.1.1.1
    * tcp://1.1.1.1:53
    * tls://1.1.1.1:853
    * https://1.0.0.1/dns-query

## Resolver In Chain

Resolver can be set on a hop or a node in the forwarding chain. When no resolver is set on the node, the resolver on the hop is used.

=== "CLI"
	```
	gost -L http://:8000 -F http://example.com:8080?resolver=1.1.1.1,tcp://8.8.8.8,tls://8.8.8.8:853,https://1.0.0.1/dns-query
	```

	Use the `resolver` option to specify the list of upper-level DNS. The `resolver` option corresponds to the hop-level resolver in the configuration file.

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8000"
      handler:
        type: http
		chain: chain-0
      listener:
        type: tcp
	chains:
    - name: chain-0
      hops:
      - name: hop-0
	    # hop level resolver
        resolver: resolver-0
        nodes:
		- name: node-0
		  addr: example.com:8080
	      # node level resolver
          # resolver: resolver-0
		  connector:
			type: http
		  dialer:
			type: tcp
	resolvers:
	- name: resolver-0
	  nameservers:
	  - addr: 1.1.1.1
	  - addr: tcp://8.8.8.8
	  - addr: tls://8.8.8.8:853
	  - addr: https://1.0.0.1/dns-query
	```

	Use the `resolver` property in the hop or node of the forwarding chain to use the specified resolver by referencing the resolver name.

## Use Forwarding Chain

Each upper-level DNS in the resolver can set the forwarding chain separately.

```yaml
services:
- name: service-0
  addr: ":8080"
  resolver: resolver-0
  handler:
	type: http
  listener:
	type: tcp
chains:
- name: chain-0
  hops:
  - name: hop-0
	nodes:
	- name: node-0
	  addr: 192.168.1.1:8081
	  connector:
		type: http
	  dialer:
		type: tcp
- name: chain-1
  hops:
  - name: hop-0
	nodes:
	- name: node-0
	  addr: 192.168.1.2:8082
	  connector:
		type: socks5
	  dialer:
		type: tcp
- name: chain-2
  hops:
  - name: hop-0
	nodes:
	- name: node-0
	  addr: 192.168.1.3:8083
	  connector:
		type: relay
	  dialer:
		type: tls
resolvers:
- name: resolver-0
  nameservers:
  - addr: 1.1.1.1
  - addr: tcp://8.8.8.8:53
	chain: chain-0
  - addr: tls://8.8.8.8:853
	chain: chain-1
  - addr: https://1.0.0.1/dns-query
	chain: chain-2
```

## Cache

There is a cache inside each resolver. The cache duration can be set through the `ttl` property. By default, the TTL in the result returned by the DNS query is used. When it is set to a negative value, the cache is not used.

```yaml
resolvers:
- name: resolver-0
  nameservers:
  - addr: 1.1.1.1
    ttl: 30s
```

## Prefer IPv6

Resolver returns IPv4 addresses by default and can be switched to IPv6 addresses by setting the `prefer` option.

```yaml
resolvers:
- name: resolver-0
  nameservers:
  - addr: 1.1.1.1
    prefer: ipv6 # default is ipv4
```

## IPv4/IPv6 Only

Only IPv4 or IPv6 addresses can be used via the `only` option. When the `only` option is set, the `prefer` option will be ignored.

```yaml hl_lines="5"
resolvers:
- name: resolver-0
  nameservers:
  - addr: 1.1.1.1
    only: ipv6 # or ipv4
```

## Asynchronous Query

Use the `async` option to set the query request to the DNS service to be asynchronous. At this time, when the cache is expired, the result in the cache will still be returned, and at the same time, the query request will be sent to the  DNS service asynchronously and the cache will be updated.

```yaml hl_lines="5"
resolvers:
- name: resolver-0
  nameservers:
  - addr: 1.1.1.1
    async: true
```

## ECS

Set the client IP through the `clientIP` property, and enable the ECS (EDNS Client Subnet) extension function.

```yaml
resolvers:
- name: resolver-0
  nameservers:
  - addr: 1.1.1.1
    clientIP: 1.2.3.4
```

## Plugin

Resolver can be configured to use an external [plugin](/en/concepts/plugin/) service, and authenticator will forward the request to the plugin server for processing. Other parameters are invalid when using plugin.

```yaml
resolvers:
- name: resolver-0
  plugin:
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

`addr` (string, required)
:    plugin server address.

`tls` (duration, default=null)
:    TLS encryption will be used for transmission, TLS encryption is not used by default.

### HTTP Plugin

```yaml
resolvers:
- name: resolver-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/resolver
```

#### Example

```bash
curl -XPOST http://127.0.0.1:8000/resolver -d '{"network": "ip4", "host":"example.com", "client": "gost"}'
```

```json
{"ips": ["1.2.3.4","2.3.4.5"], "ok": true}
```

`network` (string, default=ip4)
:    network type: `ip4` - ipv4。`ip6` - ipv6

`host` (string)
:    host address

`client` (string)
:    user ID, generated by Authenticator plugin.

`ips` ([]string)
:    IP address list

