# SOCKSv5

Name: `socks`, `socks5`

Status： Stable

The SOCKS5 handler uses the SOCKSv5 proxy protocol for data exchange, receiving and processing client requests.

=== "CLI"
    ```
	gost -L socks://:1080
	```
=== "File (YAML)"
    ```yaml
	services:
	- name: service-0
	  addr: ":1080"
	  handler:
		type: socks
	  listener:
		type: tcp
	```

## 参数列表

`readTimeout` (time.Duration, default=15s):
:    The timeout duration for reading request data.

`notls` (bool, default=false):
:    Disables the TLS negotiation encryption extension protocol.

`bind` (bool, default=false):
:    Enables the BIND feature, allowing the SOCKS5 handler to establish a remote connection without relaying the data.

`udp` (bool, default=false):
:    Enables UDP forwarding. Set to `true` to allow UDP traffic through the SOCKS5 proxy.

`udpBufferSize` (int, default=4096):
:    The size of the UDP data buffer in bytes. The value is bounded to a minimum of 512 bytes and a maximum of 64KB.

`comp` (bool, default=false):
:    Compatibility mode. When enabled, the BIND feature will work with GOSTv2 configurations.

`tor` (bool, default=false):
:    Enables Tor SOCKS5 extension command support. When enabled, the handler accepts and forwards `0xF0` RESOLVE (hostname-to-IP) and `0xF1` RESOLVE_PTR (reverse DNS) commands to the upstream proxy. Use `tor=true`, `enableTor=true`, or `socks5.tor=true`.

!!! example "Tor Resolve"
    ```
	gost -L "socks5://:1080?tor=true" -F "socks5://127.0.0.1:9050"
	tor-resolve example.com 127.0.0.1:1080
	```

`hash` (string):
:    A hash value used for verification or identification in the SOCKS5 connection.

`observePeriod` (time.Duration, default=5s):
:    The period for observing traffic activity. If not specified, it defaults to 5 seconds.

`observer.resetTraffic` (bool):
:    Whether to reset traffic counters during observation periods.

`sniffing` (bool):
:    Whether to enable traffic sniffing. Set to `true` to capture data packets for analysis.

`sniffing.timeout` (time.Duration):
:    The timeout duration for sniffing traffic.

`sniffing.websocket` (bool):
:    Whether to sniff WebSocket traffic in addition to regular SOCKS5 traffic.

`sniffing.websocket.sampleRate` (float64):
:    The sample rate for capturing WebSocket traffic packets.

`limiterRefreshInterval` (time.Duration):
:    The refresh interval for the rate limiter that controls the allowed data rate.

`limiterCleanupInterval` (time.Duration):
:    The cleanup interval for clearing expired entries in the rate limiter.
