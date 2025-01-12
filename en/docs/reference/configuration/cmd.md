# Command Line 

GOST currently has the following command line options:

> **`-L`** - Specify service. You can set multiple services.

The value of this parameter is in URL-like format (the content in square brackets can be omitted):

```text
[scheme://][username:password@host]:port[?key1=value1&key2=value2]
```

For port forwarding mode

```text
scheme://[bind_address]:port/[host]:hostport[?key1=value1&key2=value2]
```

`scheme`
:    It can be a combination of a handler and a listener, or a single handler (the listener defaults to tcp) or a listener (the handler defaults to auto), for example:

    * `http+tls` - The combination of the http handler and the tls listener specifies the HTTPS proxy service.
    * `http` - Equivalent to `http+tcp`, the combination of the handler http and the listener tcp, specifies the HTTP proxy service.
    * `tcp` - Equivalent to `tcp+tcp`, a combination of handler tcp and listener tcp, specifies TCP port forwarding.
    * `tls` - Equivalent to `auto+tls`, a combination of handler auto and listener tls.

!!! example

    ```bash
    gost -L http://:8080
    ```

    ```bash
    gost -L http://:8080 -L socks5://:1080?foo=bar
    ```

    ```bash
    gost -L http+tls://gost:gost@:8443
    ```

    ```bash
    gost -L tcp://:8080/192.168.1.1:80
    ```

    ```bash
    gost -L tls://:8443
    ```

!!! tip "Address List"
    Port forwarding mode supports the following forwarding target address list format:

    ```bash
    gost -L tcp://:8080/192.168.1.1:80,192.168.1.2:80,192.168.1.3:8080
    ```

> **`-F`** - Specify a forwarding node. You can set multiple nodes to form a forwarding chain.

This parameter value is in URL-like format (the content in square brackets can be omitted).

```text
[scheme://][username:password@host]:port[?key1=value1&key2=value2]
```

`scheme`
:    It can be a combination of a connector and a dialer, or a single connector (the default for the dialer is tcp) or a dialer (the default for the connector is http), for example:

       * `http+tls` - A combination of connector http and dialer tls, specifying the HTTPS proxy node.
       * `http` - Equivalent to `http+tcp`, a combination of the handler http and the listener tcp, specifying the HTTP proxy node.
	   * `tls` - Equivalent to `http+tls`.

!!! example

    ```bash
    gost -L http://:8080 -F http://gost:gost@192.168.1.1:8080 -F socks5+tls://192.168.1.2:1080?foo=bar
    ```

!!! tip "Node Group"
    You can also form a node group by setting an address list:

    ```bash
    gost -L http://:8080 -F http://gost:gost@192.168.1.1:8080,192.168.1.2:8080
    ```

> **`-C`** - Specifies an external configuration file.

!!! example
    Use the configuration file `gost.yml`

    ```bash
    gost -C gost.yml
    ```

> **`-O`** - Specify the configuration output format, currently supports `yaml` or `json`.

!!! example

    Output yaml format configuration:

    ```bash
    gost -L http://:8080 -O yaml
    ```

    Output json format configuration:

    ```bash
    gost -L http://:8080 -O json
    ```

    Convert json format configuration to yaml format:

    ```bash
    gost -C gost.json -O yaml
    ```

> **`-D`** - Enable Debug mode for more detailed log output.

!!! example

    ```bash
    gost -L http://:8080 -D
    ```

> **`-DD` - Enable Trace mode to output more detailed log information than Debug mode.

!!! example

    ```bash
    gost -L http://:8080 -DD
    ```

> **`-V`** - Print version.

!!! example

    ```bash
    gost -V
    ```

> **`-api`** - Specify the web API address.

!!! example

    ```bash
    gost -L http://:8080 -api :18080
    ```

> **`-metrics`** - Specify prometheus metrics API address.

!!! example

    ```bash
    gost -L http://:8080 -metrics :9000
    ```

!!! tip "Handle special characters in command line scheme"
    Zsh in macOS does not support `?` and `&`, you have to use `""` to quote them,otherwise you'll get warnings in Terminal: "zsh: no matches found: ..."。

=== "Bash"

    ```bash
    gost -L http://:8080 -L socks5://:1080?foo=bar
    ```

=== "Zsh"

    ```bash
    gost -L http://:8080 -L "socks5://:1080?foo=bar"
    ```
