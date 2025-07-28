---
comments: true
---

# Service

!!! tip "Dynamic configuration"
    Service supports dynamic configuration via [Web API](../tutorials/api/overview.md).

!!! tip "Everything as a Service"
    In GOST, the client and the server are relative, and the client itself is also a service. If a forwarding chain or forwarder is used, the node in it is regarded as the server.

Service is the fundamental module of GOST and the entrance to the GOST program. Both the server and the client are built on the basis of services.

A service consists of a listener as a data channel, a handler for data processing and an optional forwarder for port forwarding.

=== "CLI"

    ```bash
    gost -L http://:8080
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: http
      listener:
        type: tcp
    ```

## Workflow

When a service is running, the listener will listen on the specified port according to the configuration of the service and communicate using the specified protocol. After receiving the correct data, the listener establishes a data channel connection and hands this connection to the handler for use. The handler performs data communication according to the specified protocol, and after receiving the request from the client, obtains the target address. If a forwarder is used, the target address specified in the forwarder is used, and then the router is used to send the request to the target host.

!!! tip "Router"
    Router is an abstract module inside the handler, which contains the forwarding chain, resolver, host mapper, etc., for request routing between the service and the target host.

## Service Status and Stats

When viewing the service configuration through the [web API](../tutorials/api/overview.md), the status of each service is recorded in the `status` field in the configuration of the service.

```json hl_lines="12-29"

{
  "services": [
    {
      "name": "service-0",
      "addr": ":8080",
      "handler": {
        "type": "auto"
      },
      "listener": {
        "type": "tcp"
      },
      "status": {
        "createTime": 1736657921,
        "state": "ready",
        "events": [
          {
            "time": 1736657921,
            "msg": "service service-0 is running"
          },
          {
            "time": 1736657921,
            "msg": "service service-0 is ready"
          },
          {
            "time": 1736657921,
            "msg": "service service-0 is listening on [::]:8080"
          }
        ]
      }
    }
  ]
}

```

`status.createTime` (int64)
:    Service creation time (Unix timestamp).

`status.state` (string)
:    Status of service: `running`, `ready`, `failed`, `closed`.

`status.events` (string)
:    List of service status.


If stats are enabled for a service via the `enableStats` option, stats for this service will be recorded in `status.stats`.

```json hl_lines="13 32-38"
{
  "services": [
    {
      "name": "service-0",
      "addr": ":8080",
      "handler": {
        "type": "auto",
      },
      "listener": {
        "type": "tcp",
      },
      "metadata": {
        "enableStats": "true"
      },
      "status": {
        "createTime": 1736658090,
        "state": "ready",
        "events": [
          {
            "time": 1736658090,
            "msg": "service service-0 is running"
          },
          {
            "time": 1736658090,
            "msg": "service service-0 is ready"
          },
          {
            "time": 1736658090,
            "msg": "service service-0 is listening on [::]:8080"
          }
        ],
        "stats": {
          "totalConns": 4,
          "currentConns": 0,
          "totalErrs": 0,
          "inputBytes": 3770,
          "outputBytes": 82953
        }
      }
    }
  ]
}
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

!!! tip "Observer"
    If an observer is used on the service, the status and stats of the service will also be reported to the plugin through the observer.

## Ignore Chain

In command line mode, if there is a forwarding chain, all services will use this forwarding chain by default. The `ignoreChain` option allows specific services not to use the forwarding chain.

```bash
gost -L http://:8080?ignoreChain=true -L socks://:1080 -F http://:8000
```

The HTTP service on port 8080 does not use the forwarding chain, and the SOCKS5 service on port 1080 uses the forwarding chain.

## Multiple Processes

In the command line mode, all services run in the same process by default, use the `--` separator to make the service run in a separate process.

```bash
gost -L http://:8080 -- -L http://:8000 -- -L socks://:1080 -F http://:8000
```

The above command will start three processes corresponding to three services, and the forwarding chain is only used by the service on port 1080.

## Execute Commands

the `preUp`, `postUp`, `preDown`, `postDown` options can be used to execute additional commands before and after the service starts or stops.

```yaml
services:
- name: service-0
  addr: :8080
  metadata:
    preUp:
    - echo pre-up
    postUp:
    - echo post-up
    preDown:
    - echo pre-down
    postDown:
    - echo post-down
  handler:
    type: http
  listener:
    type: tcp
```