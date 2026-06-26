# MASQUE

Name: `masque`

Status: Alpha

The MASQUE handler implements RFC 9298 (Proxying UDP in HTTP) and RFC 9297 (HTTP Datagrams), supporting two forwarding modes:

- **CONNECT-UDP**: Proxies UDP datagrams via HTTP/3 Extended CONNECT (RFC 9298).
- **CONNECT-TCP**: Tunnels TCP connections over HTTP/3 streams (standard CONNECT).

The handler automatically dispatches to the appropriate mode based on the request's `:protocol` pseudo-header.

!!! tip "Default Listener"
    When no listener is specified, the MASQUE handler uses HTTP/3 as the default listener. Since MASQUE relies on HTTP/3 datagrams, the listener must have `enableDatagrams` enabled.

=== "CLI"
    ```
	gost -L masque://:8443
	```
	Equivalent to
	```
	gost -L masque+h3://:8443
	```

=== "File (YAML)"
    ```yaml
	services:
	- name: service-0
	  addr: ":8443"
	  handler:
		type: masque
	  listener:
		type: h3
		enableDatagrams: true
	```

!!! note "Limitations"
    The MASQUE handler must be used with the [HTTP/3 listener](/reference/listeners/http3/). CONNECT-UDP mode requires the listener to have `enableDatagrams` enabled.

## Parameters

`bufferSize` (int, default=4096)
:    UDP data buffer size

`hash` (string)
:    Access key. When set, a simple authorization check is performed based on the hash value. The client must include the correct hash in the request path.

`authBasicRealm` (string)
:    Basic authentication realm

`observePeriod` (duration, default=5s)
:    Observation period for periodic traffic statistics reporting.

`observer.resetTraffic` (bool, default=false)
:    Reset traffic statistics on observation.

`limiter.refreshInterval` (duration)
:    Limiter refresh interval.

`limiter.cleanupInterval` (duration)
:    Limiter cleanup interval.

`idleTimeout` (duration)
:    TCP connection idle timeout. When no data is transferred on the bidirectional TCP relay within this duration, the connection is closed. Can be specified via `idleTimeout` or `readTimeout`.

For TLS configuration, refer to [TLS Configuration](/tutorials/tls/).
