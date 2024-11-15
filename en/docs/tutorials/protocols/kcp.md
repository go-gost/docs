---
comments: true
---

# KCP

KCP is a data channel type in GOST. The implementation of KCP depends on the [xtaci/kcp-go](https://github.com/xtaci/kcp-go) library.

## Usage

=== "CLI"

    ```bash
    gost -L kcp://:8443?kcp.configFile=/path/to/config/file
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8443"
      handler:
        type: auto
      listener:
        type: kcp
        metadata:
          # config file
          kcp.configFile: /path/to/config/file
          # config map
          kcp.config:
            key: "it's a secrect"
            crypt: aes
            mode: fast
            mtu: 1350
            tcp: false
            # ...
          # single config option
          kcp.crypt: aes
          kcp.mode: fast
    ```

## Configuration

GOST has a built-in set of default KCP configuration items, and the default values ​​are consistent with [xtaci/kcptun](https://github.com/xtaci/kcptun).

You can specify the configuration directly through `kcp.config` option. You can also specify an external configuration file through `kcp.configFile` option. The configuration file is in JSON format:

```json
{
    "key": "it's a secrect",
    "crypt": "aes",
    "mode": "fast",
    "mtu" : 1350,
    "sndwnd": 1024,
    "rcvwnd": 1024,
    "datashard": 10,
    "parityshard": 3,
    "dscp": 0,
    "nocomp": false,
    "acknodelay": false,
    "nodelay": 0,
    "interval": 40,
    "resend": 0,
    "nc": 0,
    "smuxver": 1,
    "sockbuf": 4194304,
    "keepalive": 10,
    "snmplog": "",
    "snmpperiod": 60,
    "tcp": false
}
```

Some parameters can also be specified directly through options:

`kcp.tcp`:
:    config.tcp   

`kcp.key`:
:    config.key

`kcp.crypt`:
:    config.crypt
  
`kcp.mode`:
:    config.mode

`kcp.keepalive`:
:    config.keepalive

`kcp.interval`:
:    config.interval
    
`kcp.mtu`:
:    config.mtu

`kcp.smuxver`:
:    config.smuxver

For a description of the parameters in the configuration file, see [kcptun](https://github.com/xtaci/kcptun#usage).

## Proxy

KCP tunnel can be used in combination with various proxy protocols.

### HTTP Over KCP

=== "CLI"

    ```bash
    gost -L http+kcp://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: kcp
    ```

### SOCKS5 Over KCP

=== "CLI"

    ```bash
    gost -L socks5+kcp://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: socks5
      listener:
        type: kcp
    ```

### Relay Over KCP

=== "CLI"

    ```bash
    gost -L relay+kcp://:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: kcp
    ```

## Port Forwarding

KCP tunnel can also be used as port forwarding.

**Server**

=== "CLI"

    ```bash
    gost -L kcp://:8443/:8080 -L ss://:8080
    ```

    is equivalent to

    ```bash
    gost -L forward+kcp://:8443/:8080 -L ss://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: forward
      listener:
        type: kcp
      forwarder:
        nodes:
        - name: target-0
          addr: :8080
    - name: service-1
      addr: :8080
      handler:
        type: http
      listener:
        type: tcp
    ```

By using port forwarding of the KCP tunnel, a KCP data channel is added to the Shadowsocks proxy service on port 8080.

At this time, port 8443 is equivalent to:

```bash
gost -L ss+kcp://:8443
```