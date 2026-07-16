---
comments: true
---

# Node Liveness Probe

:material-tag: 3.3.0

GOST supports active health checking for each node in a forwarding chain. When a node is configured with a `probe`, GOST starts a background goroutine that periodically probes the node's reachability and latency. Dead nodes are automatically excluded from the selector, and recovered nodes are re-admitted automatically.

Compared to passive failure detection (marking nodes only when real connections fail), active probing has two key advantages:

- **Pre-marking**: Nodes are marked dead before any real traffic reaches them, avoiding failed requests.
- **Latency awareness**: Combined with the `lowestlatency` strategy, the selector can always pick the lowest-latency node.

## How It Works

```
Each probed node → dedicated goroutine → periodic probe
    │
    ├─ success → Marker().Reset() → node marked healthy → FailFilter passes
    │
    └─ failure → Marker().Mark() → node marked dead → FailFilter skips
```

Probing uses the node's own transport: it calls `Dial(node.Addr)` to reach the node, then validates based on the probe type:

- **TCP**: Dial + Handshake success is sufficient.
- **HTTP**: An HTTP GET request is sent through the established tunnel and the response status code is validated.
- **Cmd**: Runs a shell command; exit code 0 = healthy, non-zero = unhealthy. Does **not** require a transport or `addr` — the command runs locally.

## Configuration

Add a `probe` block to a node:

```yaml
chains:
- name: chain-1
  hops:
  - name: hop-1
    selector:
      strategy: round
      maxFails: 1
      failTimeout: 10s
    nodes:
    - name: proxy1
      addr: 10.0.0.1:1080
      connector:
        type: socks5
      dialer:
        type: tcp
      probe:
        type: tcp
        addr: 8.8.8.8:53
        interval: 30s
        timeout: 10s
    - name: proxy2
      addr: 10.0.0.2:1080
      connector:
        type: socks5
      dialer:
        type: tcp
      probe:
        type: http
        addr: httpbin.org:80
        httpPath: /get
        expectedStatus: 200
        interval: 60s
        timeout: 15s
    - name: proxy3
      addr: proxy3.local:1080
      connector:
        type: socks5
      dialer:
        type: tcp
      probe:
        type: cmd
        command: './scripts/health-check.sh'
        interval: 60s
        timeout: 10s
```

### Parameters

`type` (string, default=tcp)
:    Probe type: `tcp`, `http`, or `cmd`.

`addr` (string, required for tcp/http)
:    Probe target address. The probe reaches this address through the node's tunnel. Not required for `type: cmd`.

`interval` (duration, default=30s)
:    Interval between probes. The first probe fires immediately at startup.

`timeout` (duration, default=10s)
:    Per-probe timeout.

`httpPath` (string, default=/)
:    Request path for HTTP probes. Only effective with `type: http`.

`httpHost` (string)
:    Host header for HTTP requests. Defaults to `addr`.

`httpHeaders` (map[string]string)
:    Additional headers for HTTP probes.

`expectedStatus` (int, default=200)
:    Expected HTTP response status code. Only effective with `type: http`.

`command` (string, required for cmd)
:    Shell command to execute. On Unix, runs via `sh -c <command>`. On Windows, runs via `cmd /C <command>`. Exit 0 = healthy, non-zero (or timeout) = unhealthy. Node's transport is not used — the command runs directly on the GOST host.

!!! note "Probe Target"
    The probe target (`addr`) is the address accessed **through** the node's tunnel. For example, `addr: 8.8.8.8:53` means connecting to `8.8.8.8:53` through proxy1's SOCKS5 tunnel. To verify the node itself is reachable, set `addr` to the node's own address.

## Selector Strategies

Active probing works with selector strategies to enable health-aware intelligent routing.

### FailFilter

All selector strategies include `FailFilter` by default. Nodes marked dead by the probe are automatically skipped:

```yaml
selector:
  strategy: round          # works with any strategy
  maxFails: 1              # consecutive marks before exclusion
  failTimeout: 10s         # how long the mark remains valid
```

When a node recovers (probe succeeds → `Marker().Reset()`), `FailFilter` re-admits it to the candidate pool.

### lowestlatency Strategy

Selects the node with the lowest probe latency:

```yaml
selector:
  strategy: lowestlatency
  maxFails: 1
  failTimeout: 10s
```

!!! note "Nodes Without Probe Results"
    Nodes without a `probe` configuration have no latency data and are deprioritized (placed last as fallbacks). Nodes with probes that fail are similarly downgraded.

### maxLatency Filter

Filters out nodes whose latency exceeds the threshold:

```yaml
selector:
  strategy: round
  maxFails: 1
  failTimeout: 10s
  maxLatency: 500ms          # nodes exceeding 500ms are filtered
```

Nodes without probe results are unaffected (conservatively passed through).

## Lifecycle

The probe goroutine is bound to the node's lifecycle:

- **Start**: Triggered during config parsing (`ParseNode`), covered by both hot-reload and initial loading.
- **Stop**: Canceled when the node `Close()`s or the parent chain is unregistered. Config reloads stop old chains before starting new ones — no goroutine leaks.

## Examples

### TCP Probe + FailFilter

Two nodes, one dead. The probe marks the dead node before any real traffic hits it — all requests succeed:

```yaml
services:
- name: proxy
  addr: :8080
  handler:
    type: http
    chain: my-chain
  listener:
    type: tcp

- name: relay
  addr: 127.0.0.1:18081
  handler:
    type: http
  listener:
    type: tcp

chains:
- name: my-chain
  hops:
  - name: hop-1
    selector:
      strategy: round
      maxFails: 1
      failTimeout: 10s
    nodes:
    - name: node-live
      addr: 127.0.0.1:18081
      connector:
        type: http
      probe:
        type: tcp
        addr: 127.0.0.1:18081
        interval: 5s
    - name: node-dead
      addr: 127.0.0.1:18082   # nothing listening here
      connector:
        type: http
      probe:
        type: tcp
        addr: 127.0.0.1:18082
        interval: 5s
```

### lowestlatency

Two live nodes, automatically picks the one with the lowest latency:

```yaml
chains:
- name: my-chain
  hops:
  - name: hop-1
    selector:
      strategy: lowestlatency
      maxFails: 1
      failTimeout: 10s
    nodes:
    - name: node-a
      addr: 127.0.0.1:18081
      connector:
        type: http
      probe:
        type: tcp
        addr: 127.0.0.1:18081
        interval: 5s
    - name: node-b
      addr: 127.0.0.1:18082
      connector:
        type: http
      probe:
        type: tcp
        addr: 127.0.0.1:18082
        interval: 5s
```

### HTTP Probe

Sends an HTTP GET request through the node's tunnel and validates the status code:

```yaml
nodes:
- name: web-proxy
  addr: 10.0.0.1:3128
  connector:
    type: http
  probe:
    type: http
    addr: httpbin.org:80
    httpPath: /status/200
    httpHost: httpbin.org
    expectedStatus: 200
    interval: 30s
    timeout: 10s
```

### Cmd Probe

Runs a shell command on the GOST host to determine node health externally. The node's transport is bypassed — useful for time-based routing, external health-check scripts, or conditions the network can't probe:

```yaml
nodes:
- name: biz-hours-only
  addr: 8.8.8.8:1080
  connector:
    type: socks5
  probe:
    type: cmd
    command: 'test $(date +%H) -ge 9 -a $(date +%H) -lt 18'
    interval: 30s
    timeout: 5s
- name: with-check
  addr: 8.8.8.8:1080
  connector:
    type: socks5
  probe:
    type: cmd
    command: './scripts/health-check.sh'
    interval: 60s
    timeout: 10s
```

Note that `addr` is **not required** for cmd probes — the command runs locally, not through the node's tunnel.

## Limitations

- **First-hop nodes**: The current implementation is accurate for first-hop / single-hop nodes (directly reachable by the client). Probing deep-hop nodes (requiring traversal through upstream hops) is not yet supported.
- **Cmd probes** run commands as the same user as the GOST process. Config files are trusted input; do not source untrusted configurations.
