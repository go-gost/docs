# H3-MASQUE

Name: `h3-masque`

Status: Alpha

The H3-MASQUE dialer establishes HTTP/3 connections over QUIC and uses HTTP/3 datagrams for UDP data forwarding.

The H3-MASQUE dialer supports multiplexing, reusing QUIC connections through a connection pool for improved performance.

!!! note "Limitations"
    The H3-MASQUE dialer must be used together with the [MASQUE connector](/reference/connectors/masque/) to build a UDP proxy service based on the MASQUE protocol (RFC 9298).

=== "CLI"
    ```
	gost -L :8080 -F masque+h3-masque://:8443
	```

=== "File (YAML)"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
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
		  addr: :8443
		  connector:
			type: masque
		  dialer:
			type: h3-masque
	```

## Parameters

`host` (string)
:    HTTP request `Host` header field value

`keepAlive` (bool, default=false)
:    Enable keepalive.

`ttl` (duration, default=10s)
:    Keepalive period, effective when `keepAlive` is true.

`handshakeTimeout` (duration, default=5s)
:    Handshake timeout

`maxIdleTimeout` (duration, default=30s)
:    Max idle timeout

`maxStreams` (int, default=100)
:    Max concurrent streams

For TLS configuration, refer to [TLS Configuration](/tutorials/tls/).
