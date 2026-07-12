---
authors:
  - ginuerzh
categories:
  - Bypass
readtime: 15
date: 2022-05-03
comments: true
---

# GOST v3 Dynamic Bypass Implementation

Original post: [https://groups.google.com/g/go-gost/c/b9Z0BcqUArw](https://groups.google.com/g/go-gost/c/b9Z0BcqUArw).

Bypass (traffic diversion) routes requests through a forwarding chain or bypasses it based on certain rules. In GOST v3, this is implemented via the [bypass](https://gost.run/concepts/bypass/) component.

GOST v3 introduced a [recorder](https://gost.run/concepts/recorder/) module, which is an alternative logging mechanism. Unlike general logging, the recorder can capture specific data, such as all client IPs accessing a service or all destination addresses being accessed.

Both bypass and recorder gained Redis support in v3. Bypass can dynamically load rules from Redis, while recorder can store data in Redis.

Using these features together, you can implement automatic bypass similar to [COW](https://github.com/cyfdecyf/cow). By default, requests do not use the forwarding chain, but when a direct connection fails, the chain is used instead.

<!-- more -->

The recorder can log all failed destination addresses to Redis. By configuring the bypass to read from the same Redis key, the bypass dynamically learns which destinations need the forwarding chain.

```yaml
services:
- name: service-0
  addr: ":8080"
  recorders:
  - name: recorder-0
    record: recorder.service.router.dial.address.error
  handler:
    type: http
    chain: chain-0
  listener:
    type: tcp
chains:
- name: chain-0
  hops:
  - name: hop-0
    bypass: bypass-0
    nodes:
    - name: node-0
      addr: 192.168.1.1:8080
      connector:
        type: http
      dialer:
        type: tcp
bypasses:
- name: bypass-0
  redis:
  addr: 127.0.0.1:6379
  db: 0
  password: 123456
  key: gost:bypasses:bypass-0
recorders:
- name: recorder-0
  redis:
  addr: 127.0.0.1:6379
  db: 0
  password: 123456
  key: gost:bypasses:bypass-0
  type: set
```

### Limitations

* **False positives cannot be automatically corrected.** Network issues can cause the recorder to log destinations that don't actually need the chain.
* **Only captures connection-establishment errors.** This works for timeouts and connection refused errors, but not for cases where the connection is established but no response is received.

For false positives, an external tool can periodically check each address in the list by attempting a direct connection — if successful, the entry can be removed.

If you have a better solution, feel free to share!
