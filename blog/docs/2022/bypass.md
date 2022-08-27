---
author: ginuerzh
author_gh_user: ginuerzh
read_time: 30min
publish_date: 2022-08-27 12:00
---


所谓的分流是指按照一定的规则对流量进行划分，再对划分后的流量执行相应的操作，以达到某种程度的流量控制。

举一个现实中的例子，对于一个网络管控比较严格的公司，流量大概可以分为以下几类：

* 非法流量 - 不被允许的流量，例如被公司禁止访问的服务，直接访问会被拒绝。
* 内网流量 - 例如访问公司内部服务器，这种流量只能在公司内网才有效，不能被转发到外网。
* 外网流量 - 例如访问外网服务，可能需要通过公司的代理服务器才能访问。

## GOST中的分流

GOST最早是在v2.6版本中增加了[分流](https://v2.gost.run/bypass/)的功能，可以通过设置一组分流规则来对流量进行划分，主要用在转发链上，根据请求的目标地址来确定路由规则。

分流的功能也被带到了v3版本中，叫做[分流器](https://gost.run/concepts/bypass/)。起初和v2版本中的功能基本上没有什么区别，但在v3.0.0-beta.4版本中对分流器的功能进行了增强，支持了分流器组，可以在一个对象上设置多个分流器以达到一种组合效果，同时节点上的分流器功能也做了改动。

## 分流器类型

按照分流器设置的位置，分流器的功能也有所不同。

### 服务上的分流器

当服务上设置了分流器，如果请求的目标地址未通过分流器(未匹配白名单规则或匹配黑名单规则)，则此请求会被拒绝。

=== "命令行"

    ```
    gost -L http://:8080?bypass=example.com
    ```

=== "配置文件"

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

8080端口的HTTP代理服务使用了黑名单分流，`example.org`的请求会正常处理，`example.com`的请求会被拒绝。

这种分流器可以用来处理非法流量，将非法请求过滤掉。

#### 分流器组

通过分流器组可以实现更加细粒度的控制，当任何一个分流器测试失败则代表未通过。

=== "配置文件"

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

以上分流器规则限定只有192.168.0.0/16网段(除了192.168.0.1)和匹配*.example.org(除了www.example.org)的域名的请求才能通过。

### 转发链层级分流器

当转发链层级或跳跃点(Hop)上设置了分流器，如果请求的目标地址未通过分流器(未匹配白名单规则或匹配黑名单规则)，则转发链将终止于此跳跃点，且不包括此跳跃点。

这种类型的分流器可以看作是纵向(垂直)分流，在转发链的纵深方向上对请求进行层层过滤。

=== "命令行"

    ```
    gost -L http://:8080 -F http://:8081?bypass=~example.com,.example.org -F http://:8082?bypass=example.com
    ```

=== "配置文件"

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

当请求`www.example.com`时未通过第一个跳跃点(hop-0)的分流器(bypass-0)，因此请求不会使用转发链。

当请求`example.com`时，通过第一个跳跃点(hop-0)的分流器(bypass-0)，但未通过第二个跳跃点(hop-1)的分流器(bypass-1)，因此请求将使用转发链第一层级的节点(:8081)进行数据转发。

当请求`www.example.org`时，通过两个跳跃点的分流器，因此请求将使用完整的转发链进行转发。

### 节点上的分流器

当转发链使用多个节点时，可以通过在节点上设置分流器来对请求进行更加细粒度分流。

这种类型的分流器可以看作是横向(水平)分流，在单个层级或跳跃点上对请求进行划分。

分流器优先于节点选择器(Selector)，因此会对节点选择的最终结果产生影响。

=== "配置文件"

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

当请求`example.com`时，通过了节点node-0上的分流器bypass-0，但未通过节点node-1上的分流器bypass-1，因此请求只会使用节点node-0进行转发。

当请求`example.org`时，未通过节点node-0上的分流器bypass-0，通过了节点node-1上的分流器，因此请求只会使用节点node-1进行转发。

## DNS分流

在v3.0.0-beta.4版本中还有一个比较大的改进，[DNS代理服务](https://gost.run/tutorials/dns/)也增加了对分流器的支持。

### DNS代理服务

与其他类型服务上的分流器类似，当DNS代理服务设置了分流器，如果DNS查询的域名未通过分流器(未匹配白名单规则或匹配黑名单规则)，则DNS代理服务返回空结果。

=== "命令行"

    ```bash
	gost -L dns://:10053/1.1.1.1?bypass=example.com
    ```

=== "配置文件"

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

当查询`example.com`时，未通过服务上的分流器bypass-0，查询将返回空结果。

!!! example "DNS查询example.com(ipv4)"

	```bash
	dig -p 10053 example.com
	```

	```
	;; QUESTION SECTION:
    ;example.com.				IN	A
	```

当查询`example.org`时，通过服务上的分流器bypass-0，查询将正常返回结果。

!!! example "DNS查询example.org(ipv4)"

	```bash
	dig -p 10053 example.org
	```

	```
	;; QUESTION SECTION:
    ;example.org.				IN	A

    ;; ANSWER SECTION:
    example.org.		74244	IN	A	93.184.216.34
	```

### 上游DNS服务节点上的分流器

类似于转发链节点上的分流器，DNS代理服务的转发器节点上也可以通过设置分流器来实现精细化分流。

=== "配置文件"

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

当查询`example.org`时，未通过目标节点target-0上的分流器bypass-0，通过了目标节点target-1的分流器bypass-1，查询将转发给节点target-1进行处理。

当查询`example.com`时，通过目标节点target-0上的分流器bypass-0，未通过目标节点target-1的分流器bypass-1，查询将转发给节点target-0进行处理。

### 组合使用

这里还是以公司网络为例将以上几种类型的分流器组合在一起使用。

假如在公司内部我们要访问进行以下几个域名的查询请求：

* illegal-domain.corp - 非法的域名，无法解析。
* domain.corp - 公司内网服务器域名，只有使用公司内部DNS服务192.168.1.1:53才能解析。
* sub-domain.corp - 子公司内网服务器域名，只有通过子公司内网DNS服务192.168.2.1:53才能解析，并且此DNS服务器需要通过公司的代理服务器192.168.1.1:1080才能访问。

=== "配置文件"

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

当查询`illegal-domain.corp`时，未通过服务上的分流器bypass-service，因此查询返回空结果。

当查询`domain.corp`时，通过了服务上的分流器bypass-service，并且通过上游DNS服务节点target-0上的分流器bypass-target-0，未通过节点target-1上的分流器bypass-target-1，因此选择使用target-0(192.168.1.1:53)作为上游DNS服务。由于target-0未通过转发链hop-0上的分流器bypass-hop-0，因此不会使用转发链。
最终结果就是对`domain.corp`的查询使用公司内网DNS服务器192.168.1.1:53进行查询。


当查询`sub-domain.corp`时，通过了服务上的分流器bypass-service，并且通过上游DNS服务节点target-1上的分流器bypass-target-1，未通过节点target-0上的分流器bypass-target-0，因此选择使用target-1(192.168.2.1:53)作为上游DNS服务。由于target-1通过了转发链hop-0上的分流器bypass-hop-0，因此会使用转发链。
最终结果就是对`sub-domain.corp`的查询通过使用公司代理服务192.168.1.1:1080使用子公司内网DNS服务器192.168.2.1:53进行查询。

