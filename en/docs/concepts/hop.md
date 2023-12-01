---
comments: true
---

# Hop

!!! tip "Dynamic configuration"
    Hop supports dynamic configuration via [Web API](/en/tutorials/api/overview/) when using reference mode.

Hop is an abstraction of the forwarding chain level and is the basic component of the forwarding chain. A hop contains one or more nodes, and a node [selector] (/concepts/selector/), each time a forwarding request is performed, by using the selector on each hop, the selector selects a node in the node group, and finally forms a route to process the request.

Hops are used in two ways: inline mode and reference mode.

## Inline Mode

Hops can be defined directly in the chain.

=== "CLI"

    ```
    gost -L http://:8080 -F https://192.168.1.1:8080 -F socks5+ws://192.168.1.2:1080
    ```

=== "File (YAML)"

    ```yaml hl_lines="12 20"
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
          addr: 192.168.1.1:8080
          connector:
            type: http
          dialer:
            type: tls
      - name: hop-1
        nodes:
        - name: node-0
          addr: 192.168.1.2:1080
          connector:
            type: socks5
          dialer:
            type: ws
    ```

The above configuration has a chain (chain-0) with two hops (hop-0, hop-1) and one node in each hop.

## Reference Mode

It is also possible to define hops individually and then use a specific hop by referencing the name of it.

```yaml hl_lines="13 14 17 25"
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
  - name: hop-1

hops:
- name: hop-0
  nodes:
  - name: node-0
    addr: 192.168.1.1:8080
    connector:
      type: http
	dialer:
      type: tls
- name: hop-1
  nodes:
  - name: node-0
    addr: 192.168.1.2:1080
    connector:
      type: socks5
    dialer:
      type: ws
```

The hops defined in `hops` are referenced by `name` in the chain.

### Forwarder

Hops can also be used in forwarder through reference mode.

```yaml hl_lines="9"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: tcp 
  listener:
    type: tcp
  forwarder:
    name: hop-0

hops:
- name: hop-0
  nodes:
  - name: target-0
    addr: 192.168.1.1:8080
  - name: target-1
    addr: 192.168.1.2:8080
```


!!! note "Mode Switch"
    When using inline mode, if no node is defined or plugin is not used in the hop, it will automatically switch to reference mode.


## Data Source

Hop can configure multiple data sources, currently supported data sources are: inline, file, redis, HTTP.

### Inline

An inline data source means setting the data directly in the configuration file via the `nodes` property.

```yaml
hops:
- name: hop-0
  nodes:
  - name: node-0
    addr: :8888
    connector:
      type: http
    dialer:
      type: tcp
  - name: node-1
    addr: :9999
    connector:
      type: socks5
    dialer:
      type: tcp
```

### File

Specify an external file as the data source. Specify the file path via the `file.path` property.

```yaml
hops:
- name: hop-0
  nodes: []
  file:
    path: /path/to/file
```

The file format is JSON array, and each item in the array is node configuration information.

```json
[
    {
        "name": "http",
        "addr": ":8888",
        "connector": {
            "type": "http",
            "auth": {
                "username": "user",
                "password": "pass"
            }
        },
        "dialer": {
            "type": "tcp"
        }
    },
    {
        "name": "socks5",
        "addr": ":9999",
        "connector": {
            "type": "socks5",
            "auth": {
                "username": "user",
                "password": "pass"
            }
        },
        "dialer": {
            "type": "tcp"
        }
    }
]
```

### Redis

Specify the redis service as the data source, and the redis data type must be [Strings](https://redis.io/docs/data-types/strings/).

```yaml
hops:
- name: hop-0
  nodes: []
  redis:
    addr: 127.0.0.1:6379
    db: 1
    password: 123456
    key: gost:hops:hop-0:nodes
```

`addr` (string, required)
:    redis address

`db` (int, default=0)
:    db name

`password` (string)
:    password

`key` (string, default=gost)
:    redis key

The data format is the same as the file data source:

```redis
> GET gost:hops:hop-0:nodes
"[{\"name\":\"http\",...},{\"name\":\"socks5\",...}]"
```

### HTTP

Specify the HTTP service as the data source. For the requested URL, if HTTP returns a 200 status code, it is considered valid, and the returned data format is the same as the file data source.

```yaml
hops:
- name: hop-0
  nodes: []
  http:
    url: http://127.0.0.1:8000
    timeout: 10s
```

`url` (string, required)
:    request URL

`timeout` (duration, default=0)
:    request timeout

## Hot Reload

File，redis，HTTP data sources support hot reloading. Enable hot loading by setting the `reload` property, which specifies the period for synchronizing the data source data.

```yaml hl_lines="3"
hops:
- name: hop-0
  reload: 10s
  file:
    path: /path/to/file
  redis:
    addr: 127.0.0.1:6379
    db: 1
    password: 123456
    key: gost:hops:hop-0:nodes
  http:
    url: http://127.0.0.1:8000
    timeout: 10s
  nodes: []
```

## Plugin

The hop can be configured to use the external [Plugin](/en/concepts/plugin/) service, and the hop will forward the node selection request to the plugin service for processing. Other parameters have no effect when using plugin.

```yaml
hops:
- name: hop-0
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
hops:
- name: hop-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/hop
```

#### Example

```bash
curl -XPOST http://127.0.0.1:8000/hop -d '{"addr": "example.com:80", "client": "gost"}'
```

```json
{
    "name": "http",
    "addr": ":8888",
    "connector": {
        "type": "http",
        "auth": {
            "username": "user",
            "password": "pass"
        }
    },
    "dialer": {
        "type": "tcp"
    }
}
```

`client` (string)
:    user ID, generated by Authenticator plugin.
