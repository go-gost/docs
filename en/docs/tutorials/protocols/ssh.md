# SSH

SSH is a data channel type in GOST.

SSH has two modes: tunnel mode and forwarding mode.

## Tunnel Mode

**Server**

=== "CLI"

    ```bash
    gost -L relay+ssh://:2222
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: relay
      listener:
        type: ssh
    ```

**Client**

=== "CLI"

    ```bash
    gost -L :8080 -F relay+ssh://:2222
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: auto
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :2222
          connector:
            type: relay
          dialer:
            type: ssh
    ```

## Forwarding Mode

The port forwarding function of the standard SSH protocol is used and only TCP is supported.

**Server**

=== "CLI"

    ```bash
    gost -L sshd://:2222
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :
      handler:
        type: sshd
      listener:
        type: sshd
    ```

**Client**

=== "CLI"

    ```bash
    gost -L tcp://:8080/:80 -F sshd://:2222
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: tcp
        chain: chain-0
      listener:
        type: tcp
	  forwarder:
	    nodes:
		- name: target-0
		  addr: :80
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :2222
          connector:
            type: sshd
          dialer:
            type: sshd
    ```

!!! tip "Use the system's native SSH service"
    In forwarding mode, the server can directly use the system's standard SSH service, such as the [OpenSSH](https://linux.die.net/man/8/sshd) (sshd) service in Linux .

## Authentication

SSH tunnel supports two authentication methods: username-password authentication and PubKey authentication.

### Username-Password Authentication

!!! caution "The Scope of Authentication information"
    In command line mode, the authentication information (user:pass) sets the authentication of the SSH tunnel (Listener and Dialer), not the Handler and Connector. This behavior is only valid when using ssh or sshd tunnels.

**Server**

=== "CLI"

    ```bash
    gost -L relay+ssh://user:pass@:2222
    ```

    ```bash
    gost -L sshd://user:pass@:2222
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: relay
      listener:
        type: ssh
        auth:
          username: user
          password: pass
    ```

**Client**

=== "CLI"

    ```bash
    gost -L :8080 -F relay+ssh://user:pass@:2222
    ```

    ```bash
    gost -L tcp://:8080/:80 -F sshd://user:pass@:2222
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: auto
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :2222
          connector:
            type: relay
          dialer:
            type: ssh
            auth:
              username: user
              password: pass
    ```

### PubKey Authentication

**Server**

The server sets the authorized client public key list through `authorizedKeys` option.

=== "CLI"

    ```bash
    gost -L "relay+ssh://:2222?authorizedKeys=/path/to/authorizedKeys"
    ```

    ```bash
    gost -L "sshd://:2222?authorizedKeys=/path/to/authorizedKeys"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: relay
      listener:
        type: ssh
        metadata:
          authorizedKeys: /path/to/authorizedKeys
    ```

**Client**

The client sets the certificate private key and private key password through the `privateKeyFile` and `passphrase` options.

=== "CLI"

    ```bash
    gost -L :8080 -F "relay+ssh://:2222?privateKeyFile=/path/to/privateKeyFile&passphrase=123456"
    ```

    ```bash
    gost -L tcp://:8080/:80 -F "sshd://:2222?privateKeyFile=/path/to/privateKeyFile&passphrase=123456"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: auto
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :2222
          connector:
            type: relay
          dialer:
            type: ssh
			metadata:
			  privateKeyFile: /path/to/privateKeyFile
			  passphrase: "123456"
    ```


### Keep-Alive

The client can enable keep-alive through `keepalive` option and set the interval for sending heartbeat packets through `ttl` option (default value is 30s).

You can also set the heartbeat timeout duration (default value is 15s) through `keepalive.timeout` option and the number of heartbeat retries (default value is 1) through `keepalive.retries` option.

=== "CLI"

    ```bash
    gost -L :8080 -F "relay+ssh://:2222?keepalive=true&ttl=30s"
    ```

    ```bash
    gost -L tcp://:8080/:80 -F "sshd://:2222?keepalive=true&ttl=30s"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: auto
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :2222
          connector:
            type: relay
          dialer:
            type: ssh
			metadata:
			  keepalive: true
			  ttl: 30s
			  keepalive.timeout: 15s
			  keepalive.retries: 1
    ```

## Proxy

SSH tunnel can be used in combination with various proxy protocols.

### HTTP Over SSH

=== "CLI"

    ```bash
    gost -L http+ssh://:2222
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: http
      listener:
        type: ssh
    ```

### SOCKS5 Over SSH

=== "CLI"

    ```bash
    gost -L socks5+ssh://:2222
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: socks5
      listener:
        type: ssh
    ```

### Relay Over SSH

=== "CLI"

    ```bash
    gost -L relay+ssh://:2222
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: relay
      listener:
        type: ssh
    ```

## Port Forwarding

SSH tunnel can also be used as port forwarding.


**Server**

=== "CLI"

    ```bash
    gost -L ssh://:2222/:1080 -L socks5://:1080
    ```

    is equivalent to

    ```bash
    gost -L forward+ssh://:2222/:1080 -L socks5://:1080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :2222
      handler:
        type: forward
      listener:
        type: ssh
      forwarder:
        nodes:
        - name: target-0
          addr: :1080
    - name: service-1
      addr: :1080
      handler:
        type: socks5
      listener:
        type: tcp
    ```


By using port forwarding of the SSH tunnel, a SSH data channel is added to the SOCKS5 proxy service on port 1080.

At this time, port 2222 is equivalent to:

```bash
gost -L socks5+ssh://:2222
```
