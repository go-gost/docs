---
comments: true
---

# Dynamic configuration

GOST can be dynamically configured through Web API. The objects that support dynamic configuration are: service, chain, auther, bypass, admission controller, resolver, hosts. Configuration changes take effect immediately.

For detailed description, please refer to the online [API documentation](/swagger-ui/).

!!! tip "Immutability"
    In GOST, all dynamically configured objects are immutable instances. Subsequent update operations generate a new object instance to replace the existing one.

## Config

### Get Current Config

```sh
curl https://gost.run/play/webapi/config?format=json
```

### Save Config

Save the current configuration to the `gost.json` or `gost.yaml` file.

```sh
curl -X POST https://gost.run/play/webapi/config?format=yaml
```

## Service

Services can be dynamically configured through Web API.

### Create a New Service

Adding a new service will not affect the existing service. If the configuration is successful, the service will take effect immediately.

```sh
curl https://gost.run/play/webapi/config/services -d \
'{"name":"service-0","addr":":8080","handler":{"type":"http"},"listener":{"type":"tcp"}}'
```

### Update Service

Updating an existing service will cause the service to restart.

```sh
curl -X PUT https://gost.run/play/webapi/config/services/service-0 -d \
'{"name":"service-0","addr":":8080","handler":{"type":"socks5"},"listener":{"type":"tcp"}}'
```

### Delete Service

Deleting an existing service immediately shuts down and deletes the service.

```sh
curl -X DELETE https://gost.run/play/webapi/config/services/service-0 
```

## Forwarding Chain

!!! tip "Forward Reference"
    The configuration in GOST supports forward reference. When an object references another object (for example, a service refers to a forwarding chain), the referenced object may not exist, and the reference can be made valid by adding this object later.

### Create Chain

After the forwarding chain is successfully configured, the objects referencing this forwarding chain will take effect immediately.

```sh
curl https://gost.run/play/webapi/config/chains -d \
'{"name":"chain-0","hops":[{"name":"hop-0", 
"nodes":[{"name":"node-0","addr":":1080", 
"connector":{"type":"http"},"dialer":{"type":"tcp"}}]}]}'
```

### Update Chain

Replaces an existing forward chain object with the requested configuration.

```sh
curl -X PUT https://gost.run/play/webapi/config/chains/chain-0 -d \
'{"name":"chain-0","hops":[{"name":"hop-0", 
"nodes":[{"name":"node-0","addr":":1080", 
"connector":{"type":"socks5"},"dialer":{"type":"tcp"}}]}]}'
```

### Delete Chain

```sh
curl -X DELETE https://gost.run/play/webapi/config/chains/chain-0 
```
