# Command Line 

## Usage

GOST has the following command line options:

### **`-L`** - Specify local service(s)

The value of this parameter is in URL-like format (the content in square brackets can be omitted):

```text
[scheme://][username:password@host]:port[?key1=value1&key2=value2]
```

For port forwarding mode

```text
scheme://[bind_address]:port/[host]:hostport[?key1=value1&key2=value2]
```

#### scheme

It can be a combination of a handler and a listener, or a single handler (the listener defaults to tcp) or a listener (the handler defaults to auto), for example:

* `http+tls` - The combination of the http handler and the tls listener specifies the HTTPS proxy service.
* `http` - Equivalent to `http+tcp`, the combination of the handler http and the listener tcp, specifies the HTTP proxy service.
* `tcp` - Equivalent to `tcp+tcp`, a combination of handler tcp and listener tcp, specifies TCP port forwarding.
* `tls` - Equivalent to `auto+tls`, a combination of handler auto and listener tls.

```bash
# http+tcp
gost -L http://:8080

# http+tcp -> socks5+tcp
gost -L http://:8080 -L socks5://:1080?foo=bar

# http+tls
gost -L http+tls://gost:gost@:8443

# auto+tls
gost -L tls://:8443

# tcp+tcp或forward+tcp
gost -L tcp://:8080/192.168.1.1:80

# Port forwarding mode supports the following forwarding target address list format:
gost -L tcp://:8080/192.168.1.1:80,192.168.1.2:80,192.168.1.3:8080
```


### **`-F`** - Specify forwarding node(s) to form a forwarding chain

This parameter value is in URL-like format (the content in square brackets can be omitted).

```text
[scheme://][username:password@host]:port[?key1=value1&key2=value2]
```

#### scheme

It can be a combination of a connector and a dialer, or a single connector (the default for the dialer is tcp) or a dialer (the default for the connector is http), for example:

* `http+tls` - A combination of connector http and dialer tls, specifying the HTTPS proxy node.
* `http` - Equivalent to `http+tcp`, a combination of the handler http and the listener tcp, specifying the HTTP proxy node.
* `tls` - Equivalent to `http+tls`.

```bash
# multi-level forwarding
gost -L http://:8080 \
     -F http://gost:gost@192.168.1.1:8080 \
     -F socks5+tls://192.168.1.2:1080?foo=bar

# You can also form a node group by setting an address list:
gost -L http://:8080 -F http://gost:gost@192.168.1.1:8080,192.168.1.2:8080
```

!!! note "Special Characters"

    On some systems, certain characters (for example `&`, `!`) have special meanings and functions in command lines. If the scheme contains these special characters, use double quotes `"`.

    ```bash
    gost -L http://:8080 -L "socks5://:1080?foo=bar&bar=baz"
    ```

### **`-C`** - Specify the path or content of the external configuration file

```sh
# Use the configuration file gost.yml
gost -C /etc/gost/gost.yml

# Inline mode.
gost -C '{"api":{"addr":":8080"}}'

# Read from stdin:
gost -C - < gost.yml
```

### **`-O`** - Specify the configuration output format

Currently supports `yaml`and `json` formats.

```bash
# Output yaml format configuration:
gost -L http://:8080 -O yaml

# Output json format configuration:
gost -L http://:8080 -O json

# Convert json format configuration to yaml format:
gost -C gost.json -O yaml

# Convert yaml format configuration to json format:
gost -C gost.yaml -O json
```

### **`-D`** - Enable Debug log level

Debug level has more detailed [log](../../tutorials/log.md) output than info level and is generally used for development and debugging.

```bash
gost -L http://:8080 -D
```

### **`-DD`** - Enable Trace log level

Output more detailed [log](../../tutorials/log.md) information than debug level.

```bash
gost -L http://:8080 -DD
```

### **`-V`** - Print version

```bash
gost -V
# gost 3.0.0 (go1.24.0 linux/amd64)
```

### **`-api`** - Specify the web API address

```bash
gost -L http://:8080 -api :18080
```

Please refer to [WebAPI](../../tutorials/api/overview.md) for more details.

### **`-metrics`** - Specify prometheus metrics API address

```bash
gost -L http://:8080 -metrics :9000
```

Please refer to [Metrics](../../tutorials/metrics.md) for more details.

## Scoped Parameters

:material-tag: 3.2.1

Most parameters set in command line mode are passed down by default. For example, for service, they will affect the service, the listener, and the handler in the service. For forwarding chain, they will affect the hop, the node, and the dialer and connector in the node.

Scoped parameters are defined by using a scope-qualified prefix before the parameter to specify the scope of the parameter.

Currently supported prefixes are:

* `service.` - service level
* `listener.` - listener level
* `handler.` - handler level
* `hop.` - hop level
* `node.` - node level
* `dialer.` - dialer level
* `connector.` - connector level

=== "CLI"

    ```bash
    gost -L ":8080?handler.key1=value1&listener.key2=value2&service.key3=value3" \
         -F "http://:8000?hop.key4=value4&node.key5=value5&dialer.key6=value6&connector.key7=value7"
    ```

=== "File (YAML)"

    ```yaml
    services:
      - name: service-0
        addr: :8080
        handler:
          type: auto
          metadata:
            key1: value1
        listener:
          type: tcp
          metadata:
            key2: value2
        metadata:
          key3: value3
    chains:
      - name: chain-0
        hops:
          - name: hop-0
            nodes:
              - name: node-0
                addr: :8000
                connector:
                  type: http
                  metadata:
                    key7: value7
                dialer:
                  type: tcp
                  metadata:
                    key6: value6
                metadata:
                  key5: value5
            metadata:
              key4: value4
    ```

`key1` limited to handler level parameter, corresponding to `handler.metadata.key1`.

`key2` limited to listener level parameter, corresponding to `listener.metadata.key2`.

`key3` limited to service level parameter, corresponding to `service.metadata.key3`.

`key4` limited to hop level parameter, corresponding to `hop.metadata.key4`.

`key5` limited to node level parameter, corresponding to `node.metadata.key5`.

`key6` limited to dialer level parameter, corresponding to `dialer.metadata.key6`.

`key7` limited to connector level parameter, corresponding to `connector.metadata.key7`.


