# Bypass

!!! tip "Dynamic configuration"
    Bypass supports dynamic configuration via Web API.

## Bypass Controller

Bypass can be set for each node in the forwarding chain. During the data forwarding, whether to continue forwarding is decided according to the node bypass.

=== "CLI"

    ```bash
    gost -L http://:8080?bypass=10.0.0.0/8 -F http://192.168.1.1:8080?bypass=172.10.0.0/16,127.0.0.1,localhost,*.example.com,.example.org
    ```

    Specify a list of client address matching rules (comma-separated IP or CIDR) via the `bypass` option.


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
      - 172.10.0.0/16
      - 127.0.0.1
      - localhost
      - '*.example.com'
      - .example.org
    ```

    Use the `bypass` property in node to use the specified bypass by referencing the bypass name.

!!! tip "Hop Level Bypass"
    Bypass can be set on hop or node, if not set on node, the bypass specified on hop will be used.

    The bypass option in command line mode will be applied to the hop level.

## Blacklist And Whitelist

Bypass defaults to blacklist mode. When a node is determined in a hop by node selection, the bypass on this node will be applied. If the target address of the request matches the rules in the bypass, the chain terminates at this node (and does not contain this node).

Bypass can also be set to whitelist mode, as opposed to blacklist, only if the target address matches the rules in the bypass will proceed to the next hop of node selection.

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
      reverse: true
      matchers:
      - 172.10.0.0/16
      - 127.0.0.1
      - localhost
      - '*.example.com'
      - .example.org
    ```

    Enable blacklist mode in `bypasses` by setting the `reverse` property to `true`.

!!! note "Bypass On Service"
    When a bypass is set on the service, its behavior is different from the bypass on the forwarding chain. If the request fails the bypass rule test (does not match the whitelist rule or matches the blacklist rule), the request is rejected.

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
	password: 123456
	key: gost:bypasses:bypass-0
```

`addr` (string, required)
:    redis server address

`db` (int, default=0)
:    database name

`password` (string)
:    password

`key` (string, default=gost)
:    redis key

## Hot Reload

File and redis data sources support hot reloading. Enable hot loading by setting the `reload` property, which specifies the period for synchronizing the data source data.

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
