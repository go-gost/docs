# Service Discovery

!!! note "Limitation"
    Service discovery is currently only used within [reverse proxy tunnel](/en/tutorials/reverse-proxy-tunnel-ha/).

Service discovery provides a service registrry and discovery mechanism for reverse proxy tunnel. Service discovery can currently only be used in the form of plugins.

Service discovery defines four behaviors:

* Register - When a reverse proxy tunnel client establishes a connection with the server, the server will call the plugin to register the client's connection information.
* Deregister - When the client disconnects, the server will call the plugin to remove the client's connection information.
* Renew - The server will regularly check the client connection status and feedback it to the plugin to ensure the validity of the connection information.
* Get - When the reverse proxy tunnel server cannot find the corresponding tunnel locally, it will call the plugin to obtain the tunnel connection information.

The registered service-related information includes:

* ID - The client's connection ID.
* Name - Tunnel ID.
* Node - The connected server node ID.
* Network - Network type, tcp/udp.
* Address - The address of the connected server node.

## Plugin

Service discovery can be configured to use external [plugin](/en/concepts/plugin/) services.

```yaml
sds:
- name: sd-0
  plugin:
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

`addr` (string, required)
:    Plugin server address.

`tls` (duration, default=null)
:    TLS encryption will be used for transmission, TLS encryption is not used by default.

### HTTP Plugin

```yaml
sds:
- name: sd-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/sd
```

#### Example

**Register**

```bash
curl -XPOST http://127.0.0.1:8000/sd \
-d '{"id":"c23d4f42-c892-42b3-8b74-88ab6455d33a", \
"name":"c9ef8f8c-d687-4dca-be7a-1467b6565404", \
"node":"db670b91-61a5-4f7c-8014-3bbe994446ea", \
"network":"tcp", \
"address":"10.42.0.100:80"}'
```

**Deregister**

```bash
curl -XDELETE http://127.0.0.1:8000/sd \
-d '{"id":"c23d4f42-c892-42b3-8b74-88ab6455d33a", \
"name":"c9ef8f8c-d687-4dca-be7a-1467b6565404", \
"node":"db670b91-61a5-4f7c-8014-3bbe994446ea"}'
```

**Renew**

```bash
curl -XPUT http://127.0.0.1:8000/sd \
-d '{"id":"c23d4f42-c892-42b3-8b74-88ab6455d33a", \
"name":"c9ef8f8c-d687-4dca-be7a-1467b6565404", \
"node":"db670b91-61a5-4f7c-8014-3bbe994446ea"}'
```

**Get**

```bash
curl -XGET http://127.0.0.1:8000/sd?name=c9ef8f8c-d687-4dca-be7a-1467b6565404
```

```json
{
  "services":[
    {
      "id":"c23d4f42-c892-42b3-8b74-88ab6455d33a",
      "name":"c9ef8f8c-d687-4dca-be7a-1467b6565404",
      "node":"db670b91-61a5-4f7c-8014-3bbe994446ea",
      "network":"tcp",
      "address":"10.42.0.100:80"
    }
  ]
}
```
