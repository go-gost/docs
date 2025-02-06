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
:    Specifies the timeout duration for reading from the client.

`header` (map)
:    Custom HTTP response headers.

`keepalive` (bool):
:    Whether to keep the connection alive after the request is completed. Set to `true` to enable persistent connections.

`compression` (bool):
:    Enables HTTP response compression (gzip). Set to `true` to enable compression.

`probeResist` (string)
:    Configuration for probe resistance. This includes an optional "knock" setting to enhance security by preventing unwanted probes.

`knock` (string)
:    Configures the probe resistance knock behavior, which can be useful for additional protection against unwanted probes or attacks.

`udp` (bool, default=false)
:    Whether to enable UDP forwarding. If set to `true`, the handler will forward UDP traffic in addition to HTTP.

`authBasicRealm` (string):
:    Basic authentication realm. Defines the realm for HTTP basic authentication.

`proxyAgent` (string, default="gost/3.0"):
:    The User-Agent string sent by the HTTP handler. Defaults to `gost/3.0`.

`observePeriod` (time.Duration, default=5s):
:    The period between traffic observation checks. By default, it is set to 5 seconds.

`observer.resetTraffic` (bool):
:    Whether to reset traffic data during observation. This helps in clearing traffic counters after a specific period.

`sniffing` (bool):
:    Enable packet sniffing to capture HTTP/S traffic and analyze it. Set `true` to activate.

`sniffing.timeout` (time.Duration):
:    Timeout for sniffing operations.

`sniffing.websocket` (bool):
:    Whether to sniff WebSocket traffic in addition to regular HTTP.

`sniffing.websocket.sampleRate` (float64):
:    Sample rate for WebSocket sniffing. This controls the frequency of WebSocket packet captures.

`mitmBypass` (bypass.Bypass):
:    Configuration to bypass MITM interception for specific traffic.

`limiterRefreshInterval` (time.Duration):
:    Defines the refresh interval for the rate limiter.

`limiterCleanupInterval` (time.Duration):
:    Defines the cleanup interval for expired rate limiter entries.
