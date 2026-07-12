---
authors:
  - ginuerzh
categories:
  - Bypass
readtime: 30
date: 2022-08-27
comments: true
---

# Traffic Control — Bypass

Bypass (traffic diversion) means dividing traffic according to certain rules and then performing corresponding actions on the divided traffic to achieve a degree of traffic control.

For example, in a company with strict network管控, traffic can be categorized as:

* **Illegal traffic** — disallowed traffic, such as services the company blocks access to.
* **Intranet traffic** — traffic to internal company servers, which is only valid within the company network and should not be forwarded externally.
* **External traffic** — traffic to external services, which may need to go through the company's proxy server.

<!-- more -->

## Bypass in GOST

GOST first introduced [bypass](https://v2.gost.run/bypass/) functionality in v2.6, allowing traffic to be divided based on a set of rules. It was primarily used on forwarding chains to determine routing rules based on the destination address.

This feature was carried over to v3 as the [Bypass](https://gost.run/concepts/bypass/) component. Initially similar to v2, it was enhanced in v3.0.0-beta.4 to support bypass groups (multiple bypasses on a single object for combined effects), and the bypass functionality on nodes was also modified.

## Bypass Types

Bypass behavior differs depending on where it is placed.

### Service-Level Bypass

When a bypass is set on a service, if the request's destination address does not pass the bypass (does not match a whitelist rule or matches a blacklist rule), the request is rejected.

=== "CLI"

    ```
    gost -L http://:8080?bypass=example.com
    ```

=== "Config File"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      bypass: bypass-0
      handler:
        type: http
      listener:
        type: tcp
    bypasses:
    - name: bypass-0
      matchers:
      - example.com
    ```

The HTTP proxy on port 8080 uses a blacklist bypass. Requests to `example.org` are processed normally, while requests to `example.com` are rejected.

This type of bypass can filter out illegal traffic.

#### Bypass Groups

Bypass groups allow finer-grained control. If any bypass in the group fails, the request does not pass.

=== "Config File"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      bypasses:
      - bypass-0
      - bypass-1
      handler:
        type: http
        chain: chain-0
      listener:
        type: tcp
    bypasses:
    - name: bypass-0
      whitelist: true
      matchers:
      - 192.168.0.0/16
      - *.example.org
    - name: bypass-1
      matchers:
      - 192.168.0.1
      - www.example.org
    ```

The above rules only allow requests destined for the `192.168.0.0/16` subnet (except `192.168.0.1`) and domains matching `*.example.org` (except `www.example.org`).

### Chain-Level Bypass

When a bypass is set on a chain hop, if the destination address does not pass the bypass, the chain terminates at that hop (and that hop is excluded).

This type acts as vertical bypass, filtering requests at each level of the chain.

=== "CLI"

    ```
    gost -L http://:8080 -F http://:8081?bypass=~example.com,.example.org -F http://:8082?bypass=example.com
    ```

=== "Config File"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
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
          addr: :8081
          connector:
            type: http
          dialer:
            type: tcp
      - name: hop-1
        bypass: bypass-1
        nodes:
        - name: node-0
          addr: :8082
          connector:
            type: http
          dialer:
            type: tcp
    bypasses:
    - name: bypass-0
      whitelist: true
      matchers:
      - example.com
      - .example.org
    - name: bypass-1
      matchers:
      - example.com
    ```

When requesting `www.example.com`, it fails the first hop's bypass (bypass-0), so the chain is not used.

When requesting `example.com`, it passes bypass-0 but fails bypass-1, so only the first hop node (`:8081`) is used.

When requesting `www.example.org`, it passes both bypasses, so the full chain is used.

### Node-Level Bypass

When a chain uses multiple nodes, bypasses can be set on individual nodes for more granular traffic control.

This acts as horizontal bypass, dividing traffic within a single hop.

Bypass takes precedence over the node selector, affecting the final node selection.

=== "Config File"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: http
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: :8081
          bypass: bypass-0
          connector:
            type: http
          dialer:
            type: tcp
        - name: node-1
          addr: :8082
          bypass: bypass-1
          connector:
            type: http
          dialer:
            type: tcp
    bypasses:
    - name: bypass-0
      matchers:
      - example.org
    - name: bypass-1
      matchers:
      - example.com
    ```

When requesting `example.com`, it passes node-0's bypass but fails node-1's, so only node-0 is used.

When requesting `example.org`, it fails node-0's bypass but passes node-1's, so only node-1 is used.

## DNS Bypass

In v3.0.0-beta.4, the [DNS proxy service](https://gost.run/tutorials/dns/) also gained bypass support.

### DNS Proxy Service Bypass

Similar to service-level bypass, if a DNS query's domain does not pass the bypass, the DNS proxy returns an empty result.

=== "CLI"

    ```bash
    gost -L dns://:10053/1.1.1.1?bypass=example.com
    ```

=== "Config File"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      bypass: bypass-0
      handler:
        type: dns
      listener:
        type: dns
      forwarder:
        nodes:
        - name: target-0
          addr: 1.1.1.1
    bypasses:
    - name: bypass-0
      matchers:
      - example.com
    ```

When querying `example.com`, the bypass blocks it and returns an empty result.

!!! example "DNS query for example.com (IPv4)"

    ```bash
    dig -p 10053 example.com
    ```
    ```
    ;; QUESTION SECTION:
    ;example.com.               IN  A
    ```

When querying `example.org`, it passes the bypass and returns the result normally.

!!! example "DNS query for example.org (IPv4)"

    ```bash
    dig -p 10053 example.org
    ```
    ```
    ;; QUESTION SECTION:
    ;example.org.               IN  A

    ;; ANSWER SECTION:
    example.org.        74244   IN  A   93.184.216.34
    ```

### Upstream DNS Node Bypass

Similar to chain node bypass, upstream DNS nodes can also use bypass for fine-grained control.

=== "Config File"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      handler:
        type: dns
      listener:
        type: dns
      forwarder:
        nodes:
        - name: target-0
          addr: 1.1.1.1
          bypass: bypass-0
        - name: target-1
          addr: 8.8.8.8
          bypass: bypass-1
    bypasses:
    - name: bypass-0
      matchers:
      - example.org
    - name: bypass-1
      matchers:
      - example.com
    ```

### Combined Example

Combining the above bypass types in a corporate network scenario:

* `illegal-domain.corp` — illegal domain, should not be resolved.
* `domain.corp` — internal server, resolvable only by the company DNS `192.168.1.1:53`.
* `sub-domain.corp` — subsidiary DNS, resolvable only by `192.168.2.1:53`, which is reachable through the company proxy `192.168.1.1:1080`.

=== "Config File"

    ```yaml
    services:
    - name: service-0
      addr: :10053
      bypass: bypass-service
      handler:
        type: dns
      listener:
        type: dns
      forwarder:
        nodes:
        - name: target-0
          addr: 192.168.1.1:53
          bypass: bypass-target-0
        - name: target-1
          addr: 192.168.2.1:53
          bypass: bypass-target-1
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        bypass: bypass-hop-0
        nodes:
        - name: node-0
          addr: 192.168.1.1:1080
          connector:
            type: socks5
          dialer:
            type: tcp
    bypasses:
    - name: bypass-service
      matchers:
      - illegal-domain.corp
    - name: bypass-hop-0
      whitelist: true
      matchers:
      - 192.168.2.1
    - name: bypass-target-0
      matchers:
      - sub-domain.corp
    - name: bypass-target-1
      whitelist: true
      matchers:
      - sub-domain.corp
    ```

When querying `illegal-domain.corp`, it fails the service bypass and returns empty.

When querying `domain.corp`, it passes the service bypass and target-0's bypass, so target-0 (`192.168.1.1:53`) is used without going through the chain.

When querying `sub-domain.corp`, it passes the service bypass and target-1's bypass, so target-1 (`192.168.2.1:53`) is used through the chain (company proxy `192.168.1.1:1080`).
