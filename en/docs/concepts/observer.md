---
comments: true
---

# Observer

The observer is a component used to observe the internal status of the service, including service status changes, connection and traffic statistics, and the observer reports this information through events.

!!! tip "Dynamic configuration"
    Observer supports dynamic configuration via [Web API](../tutorials/api/overview.md).


!!! note "Limitation"
    Observer are currently only available as plugins.


## Plugin

Observer can be configured to use external [plugin](plugin.md) services.

```yaml
observers:
- name: observer-0
  plugin:
    type: grpc
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

`type` (string, default=grpc)
:    plugin type: `grpc`, `http`.

`addr` (string, required)
:    Plugin server address.

`tls` (object, default=null)
:    TLS encryption will be used for transmission, TLS encryption is not used by default.

## Usage

When the status of the service changes, the status will be reported through the observer on the service. If the service has statistics enabled (`enableStats` option), connection and traffic statistics will also be reported.

```yaml hl_lines="4 10-12"
services:
- name: service-0
  addr: ":8080"
  observer: observer-0 
  handler:
    type: http
  listener:
    type: tcp
  metadata:
    enableStats: true 
    observer.period: 5s
    observer.resetTraffic: false

observers:
- name: observer-0
  plugin:
    type: grpc
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

`enableStats` (bool, default=false)
:    Whether to report connection and traffic data.

`observer.period` (duration, default=5s)
:    Observer reporting period.

`observer.resetTraffic` (bool, default=false)
:    Whether to reset traffic data. After enabling, the traffic reported each time is incremental data.

## HTTP Plugin

```yaml
observers:
- name: observer-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/observer
    timeout: 10s
```

`timeout` (duration, default=0s)
:   Request timeout.

### Example

#### Report Service Status

```bash
curl -XPOST http://127.0.0.1:8000/observer \
-d '{"events":[
{"kind":"service","service":"service-0","type":"status", 
"status":{"state":"running","msg":"service service-0 is running"}} 
]}'
```

`kind` (string)
:    kind of event: `service` - service level, `handler` - handler level

`service` (string)
:    service name

`type` (string)
:    event types: `status` - service status, `stats` - statistics

`status.state` (string)
:    status of service: `running`, `ready`, `failed`, `closed`

`status.msg` (string)
:    description of status

#### Report Statistic*

A single service will report statistics through the observer periodically (5 seconds), and stop reporting when the service's statistics is not updated (without any connection or traffic changes).

```bash
curl -XPOST http://127.0.0.1:8000/observer \
-d '{"events":[ 
{"kind":"service","service":"service-0","type":"stats", 
"stats":{"totalConns":1,"currentConns":0,"inputBytes":235,"outputBytes":632,"totalErrs":0}} 
]}'
```

`stats.totalConns` (uint64)
:    Total number of connections handled by the service

`stats.currentConns` (uint64)
:    The number of current pending connections of the service

`stats.inputBytes` (uint64)
:    Total number of bytes of data received by the service

`stats.outputBytes` (uint64)
:    Total number of bytes of data sent by the service

`stats.totalErrs` (uint64)
:    total number of errors in service processing requests

Response:

```json
{"ok": true}
```

!!! note "Retry Mechanism"
    When the report fails, that is, the plugin service does not return a response with `ok` equal to `true`, the observer will re-upload the failed event next time until it succeeds.

## Observer In Service Handler

For proxy services that support authentication (HTTP, HTTP2, SOCKS4, SOCKS5, Relay), the observer is also available to Handler.

```yaml hl_lines="6 8 9"
services:
- name: service-0
  addr: ":8080"
  handler:
    type: http
    observer: observer-0
    metadata:
      observer.period: 5s
      observer.resetTraffic: false
  listener:
    type: tcp

observers:
- name: observer-0
  plugin:
    addr: 127.0.0.1:8000
```

`observer.period` (duration, default=5s)
:    Observer reporting period.

`observer.resetTraffic` (bool, default=false)
:    Whether to reset traffic data. After enabling, the traffic reported each time is incremental data.

### Observer Based On Client ID

Service-level observer can only be used to observe the statistics of the overall service and cannot be divided into more detailed categories for users. If you need to implement this function, you need to use a combination of the authenticator and the observer plugin on the handler.
    
The Authenticator returns the client ID after successful authentication. GOST will pass this client ID information to the Observer plugin server again. For Tunnel handler，the value of `client` is Tunnel ID.

!!! tip "Tunnel Handler"
    For Tunnel handler, the oberver acts on a single Tunnel, the client value is the Tunnel ID.

```bash
curl -XPOST http://127.0.0.1:8000/observer \
-d '{"events":[ 
{"kind":"handler","service":"service-0","client":"user1","type":"stats", 
"stats":{"totalConns":1,"currentConns":0,"inputBytes":78,"outputBytes":574,"totalErrs":0}}, 
{"kind":"handler","service":"service-0","client":"user2","type":"stats", 
"stats":{"totalConns":1,"currentConns":0,"inputBytes":78,"outputBytes":574,"totalErrs":0}} 
]}'
```

`client` (string)
:    client or tunnel ID, generated by Authenticator.