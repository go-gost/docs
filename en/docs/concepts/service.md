# Service

!!! tip "Dynamic configuration"
    Service supports dynamic configuration via [Web API](/en/tutorials/api/overview/).

!!! tip "Everything as a Service"
    In GOST, the client and the server are relative, and the client itself is also a service. If a forwarding chain or forwarder is used, the node in it is regarded as the server.

Service is the fundamental module of GOST and the entrance to the GOST program. Both the server and the client are built on the basis of services.

A service consists of a listener as a data channel, a handler for data processing and an optional forwarder for port forwarding.

=== "CLI"

    ```sh
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

!!! info "Router"
    Router is an abstract module inside the handler, which contains the forwarding chain, resolver, host mapper, etc., for request routing between the service and the target host.

## Ignore Chain

In command line mode, if there is a forwarding chain, all services will use this forwarding chain by default. The `ignoreChain` option allows specific services not to use the forwarding chain.

```
gost -L http://:8080?ignoreChain=true -L socks://:1080 -F http://:8000
```

The HTTP service on port 8080 does not use the forwarding chain, and the SOCKS5 service on port 1080 uses the forwarding chain.

## Multiple Processes

In the command line mode, all services run in the same process by default, use the `--` separator to make the service run in a separate process.

```
gost -L http://:8080 -- -L http://:8000 -- -L socks://:1080 -F http://:8000
```

The above command will start three processes corresponding to three services, and the forwarding chain is only used by the service on port 1080.

## Execute Commands (Linux Only)

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