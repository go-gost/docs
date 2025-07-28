---
comments: true
---

# Bypass

!!! tip "Dynamic configuration"
    Bypass supports dynamic configuration via [Web API](../tutorials/api/overview.md).

## Bypass Controller

Bypass can be set on the service, the hop and the nodes of the forwarding chain respectively, during the data forwarding process, the target address is tested according to the rules in the bypass to decide whether to continue forwarding.

=== "CLI"

    ```bash
    gost -L http://:8080?bypass=10.0.0.0/8 -F http://192.168.1.1:8080?bypass=172.10.0.0/16,127.0.0.1,localhost,*.example.com,.example.org
    ```

    Use the `bypass` parameter to specify the requested target address matching rule list. The rules are IP, IP range, CIDR, domain name or domain name wildcard separated by commas.

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      bypass: bypass-0
      handler:
        type: http
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        # hop level
        bypass: bypass-1
        nodes:
        - name: node-0
          addr: 192.168.1.1:8080
          # node level
          # bypass: bypass-0
          connector:
            type: http
          dialer:
            type: tcp
    bypasses:
    - name: bypass-0
      matchers:
      - 10.0.0.0/8
    - name: bypass-1
      matchers:
      - 127.0.0.1
      - 172.20.0.1-172.30.0.255
      - 172.10.0.0/16
      - localhost
      - '*.example.com'
      - .example.org
    ```

    Use the `bypass` option in node to use the specified bypass by referencing the bypass name.

!!! tip "Hop Level Bypass"
    Bypass can be set on hop or node, if not set on node, the bypass specified on hop will be used.

    The bypass option in command line mode will be applied to the hop level.

## Blacklist And Whitelist

Bypass defaults to blacklist mode. If the destination address matches the blacklist, the data forwarding will be terminated.

Bypass can also be set to whitelist mode, as opposed to blacklist, data forward will continue only if the destination address matches the rules in the bypass.

=== "CLI"

    ```bash
    gost -L http://:8080 -F http://192.168.1.1:8080?bypass=~172.10.0.0/16,127.0.0.1,localhost,*.example.com,.example.org
    ```

    Set the bypass to blacklist mode by adding the `~` prefix to the `bypass` opiton.

=== "File (YAML)"

    ```yaml
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
        bypass: bypass-0
        nodes:
        - name: node-0
          addr: 192.168.1.1:8080
          # bypass: bypass-0
          connector:
            type: http
          dialer:
            type: tcp
    bypasses:
    - name: bypass-0
      whitelist: true
      matchers:
      - 172.10.0.0/16
      - 127.0.0.1
      - localhost
      - '*.example.com'
      - .example.org
    ```

    Enable blacklist mode in `bypasses` by setting the `whitelist` property to `true`.

## Bypass Group

Multiple bypasses are used by specifying a list of bypasses using the `bypasses` option. When any one of the bypass passes the rule test, it means the bypass is passed.

=== "File (YAML)"

    ```yaml
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
        bypasses: 
        - bypass-0
        - bypass-1
        nodes:
        - name: node-0
          addr: 192.168.1.1:8080
          # bypasses: 
          # - bypass-0
          # - bypass-1
          connector:
            type: http
          dialer:
            type: tcp

    bypasses:
    - name: bypass-0
      whitelist: true
      matchers:
      - 172.10.0.0/16
    - name: bypass-1
      matchers:
      - 127.0.0.1
      - localhost
      - '*.example.com'
      - .example.org
    ```

## Port Matching

For IP, domain name and domain name wildcard rules can also contain ports or port ranges, CIDR rules do not support port matching.

=== "CLI"

    ```bash
    gost -L http://:8080?bypass=192.168.1.1:80,192.168.1.2:0-65535,example.com:80,.example.com:443
    ```

=== "File (YAML)"

    ```yaml hl_lines="4"
    services:
    - name: service-0
      addr: ":8080"
      bypass: bypass-0
      handler:
        type: http
      listener:
        type: tcp
    bypasses:
    - name: bypass-0
      matchers:
      - 192.168.1.1:80
      - 192.168.1.1:0-65535
      - '*.example.com:80'
      - .example.com:443
    ```

## Bypass Type

### Service Level Bypass

When a bypass is set on the service, if the requested target address fails the rule test (does not match the whitelist rule or matches the blacklist rule), the request will be rejected.

=== "CLI"

    ```bash
    gost -L http://:8080?bypass=example.com
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      bypass: bypass-0
      handler:
        type: http
      listener:
        type: tcp
    bypasses:
    - name: bypass-0
      matchers:
      - example.com
    ```

The HTTP proxy service on port 8080 uses a blacklist bypass. The request of `example.org` will be processed normally, and the request of `example.com` will be rejected.

### Hop Level Bypass

When a bypass is set on a hop, if the requested destination address fails the rule test (does not match the whitelist rule or matches the blacklist rule), the forwarding chain will terminate at this hop, and excluding this hop.

=== "CLI"

    ```bash
    gost -L http://:8080 -F http://:8081?bypass=~example.com,.example.org -F http://:8082?bypass=example.com
    ```

=== "File (YAML)"

    ```yaml
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
        bypass: bypass-0
        nodes:
        - name: node-0
          addr: :8081
          connector:
            type: http
          dialer:
            type: tcp
      - name: hop-1
        bypass: bypass-1
        nodes:
        - name: node-0
          addr: :8082
          connector:
            type: http
          dialer:
            type: tcp
    bypasses:
    - name: bypass-0
      whitelist: true
      matchers:
      - example.com
      - .example.org
    - name: bypass-1
      matchers:
      - example.com
    ```

When a request to `www.example.com` does not go through the bypass (bypass-0) of the hop (hop-0), the request will not use the forwarding chain.

When requesting `example.com`, it passes the bypass (bypass-0) of the first hop (hop-0), but not the bypass (bypass-1) of the second hop (hop-1) , so the request will use the node(:8081) at the first level of the forwarding chain for data forwarding.

When requesting `www.example.org`, it goes through all bypasses, so the request will be forwarded using the full forwarding chain.

### Chain Node Level Bypass

When the forwarding chain uses multiple nodes, the request can be fine-grained divided by setting bypasses on the nodes.

=== "File (YAML)"

    ```yaml
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
          addr: :8081
          bypass: bypass-0
          connector:
            type: http
          dialer:
            type: tcp
        - name: node-1
          addr: :8082
          bypass: bypass-1
          connector:
            type: http
          dialer:
            type: tcp
    bypasses:
    - name: bypass-0
      matchers:
      - example.org
    - name: bypass-1
      matchers:
      - example.com
    ```

When requesting `example.com`, it passed the bypass bypass-0 on node node-0, but did not pass the bypass bypass-1 on node node-1, so the request will only be forwarded using node node-0.

When requesting `example.org`, it does not pass the bypass-0 on node node-0, but passes the bypass on node-1, so the request will only be forwarded using node-1.

### Forwarder Node Level Bypass

This type of bypass is similar to the bypass on the chain node and currently only applies to the [DNS proxy service](../tutorials/dns.md).

## Data Source

Bypass can configure multiple data sources, currently supported data sources are: inline, file, redis.

### Inline

An inline data source means setting the data directly in the configuration file via the `matchers` property.

```yaml
bypasses:
- name: bypass-0
  matchers:
  - 127.0.0.1
  - 172.10.0.0/16
  - localhost
  - '*.example.com'
  - .example.org
```

### File

Specify an external file as the data source. Specify the file path via the `file.path` property.

```yaml
bypasses:
- name: bypass-0
  file:
    path: /path/to/bypass/file
```

The file format is a list of addresses separated by lines, and the part starting with `#` is the comment information.

```text
# ip, cidr, domain or wildcard
127.0.0.1
172.10.0.0/16
localhost
*.example.com
.example.org
```

### Redis

Specify the redis service as the data source, and the redis data type must be [Set](https://redis.io/docs/manual/data-types/#sets).

```yaml
bypasses:
- name: bypass-0
  redis:
    addr: 127.0.0.1:6379
    db: 1
    username: user
    password: 123456
    key: gost:bypasses:bypass-0
```

`addr` (string, required)
:    redis server address

`db` (int, default=0)
:    database name

`username` (string)
:    username

`password` (string)
:    password

`key` (string, default=gost)
:    redis key

```redis
> SMEMBERS gost:bypasses:bypass-0
1) "127.0.0.1"
2) "172.10.0.0/16"
3) "localhost"
4) "*.example.com"
5) ".example.org"
```

### HTTP

Specify the HTTP service as the data source. For the requested URL, if HTTP returns a 200 status code, it is considered valid, and the returned data format is the same as the file data source.

```yaml
bypasses:
- name: bypass-0
  http:
    url: http://127.0.0.1:8000
    timeout: 10s
```

`url` (string, required)
:    request URL

`timeout` (duration, default=0)
:    request timeout

## Hot Reload

File, redis and HTTP data sources support hot reloading. Enable hot loading by setting the `reload` property, which specifies the period for synchronizing the data source data.

```yaml
bypasses:
- name: bypass-0
  reload: 10s
  file:
    path: /path/to/auth/file
  redis:
    addr: 127.0.0.1:6379
	db: 1
	password: 123456
	key: gost:bypasses:bypass-0
```

## Plugin

Bypass can be configured to use an external [plugin](plugin.md) service, and it will forward the request to the plugin server for processing. Other parameters are invalid when using plugin.

```yaml
bypasses:
- name: bypass-0
  plugin:
    type: grpc
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

`type` (string, default=grpc)
:    plugin type: `grpc`, `http`.

`addr` (string, required)
:    plugin server address.

`tls` (object, default=null)
:    TLS encryption will be used for transmission, TLS encryption is not used by default.

### HTTP Plugin

```yaml
bypasses:
- name: bypass-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/bypass
```

#### Example

```bash
curl -XPOST http://127.0.0.1:8000/bypass -d '{"network":"tcp","addr":"example.com:80","path":"/index.html","client": "gost"}'
```

```json
{"ok": true}
```

`network` (string)
:    network type.

`addr` (string)
:    target address.

`host` (string)
:    target host name.

`path` (string)
:    HTTP request path.

`client` (string)
:    user ID, generated by Authenticator.

!!! tip "Bypass Based On Client ID"
    The GOST internal Bypass does not handle the logic for specific clients. If you need to implement this function, you can use an Authenticator and a Bypass plugin in combination. 
    
    The Authenticator returns the client ID after successful authentication. GOST will pass this client ID information to the Bypass plugin service again, and the Bypass plugin server can implement different strategies based on the client ID.
    