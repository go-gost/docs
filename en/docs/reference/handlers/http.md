# HTTP

Name: `http`

Status： Stable

The HTTP handler uses the standard HTTP proxy protocol to exchange data, receiving and processing HTTP requests from clients.

=== "CLI"
    ```
	gost -L http://:8080
	```
=== "File (YAML)"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
		metadata:
		  header:
		    foo: bar
	  listener:
		type: tcp
	```

## 参数列表

`readTimeout` (time.Duration, default=15s):
:    The deadline for reading upstream HTTP response headers. The default value of 0 maps to a 15-second timeout. Set to a negative value to disable the timeout entirely.

`idleTimeout` (time.Duration, default=0):
:    The idle read timeout for the CONNECT tunnel forwarding pipe. During a CONNECT tunnel, data is relayed bidirectionally between the client and the upstream. When `idleTimeout` is set to a positive value, a read deadline is applied in each direction: if no application data flows within the timeout period, the connection is terminated. This prevents resource leaks from silently-dead peers. Set to 0 or a negative value to disable the timeout entirely, allowing long-lived idle connections such as WebSockets, long-polling HTTP, slow Lambda responses, or any protocol where the tunnel may be idle for extended periods.

`header` (map):
:    Custom HTTP response headers added to every proxy response.

`keepalive` (bool):
:    Whether to keep the upstream HTTP connection alive after a request completes. Set to `true` to enable persistent connections.

`compression` (bool):
:    Whether to enable HTTP response compression (gzip). Set to `true` to enable compression.

`probeResist` (string):
:    Probe resistance configuration in the format `"type:value"`. Supported types: `"code"` (HTTP status code, e.g. `"code:404"`), `"web"` (proxy target URL), `"host"` (host address), `"file"` (response body file path). When authentication fails, a decoy response is returned instead of `407 Proxy-Auth-Required`, making the port appear to run a different service.

`knock` (string):
:    A comma-separated list of hostnames. When probe resistance is active, requests matching a knock hostname are processed normally without the decoy response. Only effective when used together with `probeResist`.

`udp` (bool, default=false):
:    Whether to enable UDP relay over HTTP (UDP-over-TCP). Set to `true` to allow UDP traffic through the HTTP proxy.

`udpBufferSize` (int):
:    The size of the UDP relay buffer in bytes.

`authBasicRealm` (string, default="gost"):
:    The realm value used in the `WWW-Authenticate` header in Basic authentication `407` responses.

`proxyAgent` (string, default="gost/3.0"):
:    The value of the `Proxy-Agent` header sent by the HTTP handler.

`hash` (string):
:    Hop node selection strategy. Set to `"host"` to use consistent hashing based on the request hostname, ensuring the same upstream node is selected for the same host.

`observePeriod` (time.Duration, default=5s):
:    The interval for reporting traffic observation statistics. If not specified, defaults to 5 seconds. Minimum value is 1 second.

`observer.resetTraffic` (bool):
:    Whether to reset traffic counters after each observation period.

`sniffing` (bool):
:    Enable protocol sniffing on CONNECT tunnels. When enabled, the handler inspects the initial bytes of the tunnel to detect HTTP or TLS traffic for protocol-aware forwarding.

`sniffing.timeout` (time.Duration):
:    The read deadline for the initial sniff peek on a CONNECT tunnel.

`sniffing.websocket` (bool):
:    Whether to enable WebSocket frame recording during sniffing.

`sniffing.websocket.sampleRate` (float64):
:    The maximum number of WebSocket frames recorded per second.

`mitm.certFile` / `mitm.keyFile` (string):
:    Paths to the CA certificate and private key files used for TLS MITM decryption. If both are provided, the handler will terminate TLS on CONNECT tunnels (man-in-the-middle mode) and inspect or modify the traffic inside.

`mitm.alpn` (string):
:    The ALPN protocol to negotiate during MITM TLS termination.

`mitm.bypass` (string):
:    Name of a bypass matcher to skip MITM decryption for matching traffic. For example, set this to a bypass that matches known-safe hostnames to exclude them from decryption.

`limiterRefreshInterval` (time.Duration):
:    The interval for refreshing rate limiter entries.

`limiterCleanupInterval` (time.Duration):
:    The interval for cleaning up expired rate limiter entries.
