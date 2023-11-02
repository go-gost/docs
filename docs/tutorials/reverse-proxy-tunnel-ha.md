# 反向代理隧道-高可用

在上一篇[反向代理隧道](/tutorials/reverse-proxy-tunnel/)教程中，详细的讲述了反向代理隧道的功能和使用方法。在本篇教程中将侧重于服务的部署及系统的高可用性方面。

## 单点故障

一个反向代理隧道系统是由三个部分组成：

* 服务端 - 反向代理隧道服务，负责隧道的管理和流量的路由。
* 客户端 - 与服务端建立隧道连接，接收服务端过来的流量，再次路由并转发到目标主机。
* 访问端 - 访问端通过入口点将请求转发给服务，服务再将流量路由到对应隧道的客户端，最终到达目标主机。

![Tunnel](/images/tunnel.png) 

在上面这个系统中存在[单点故障(SPOF)](https://zh.wikipedia.org/wiki/%E5%8D%95%E7%82%B9%E6%95%85%E9%9A%9C)问题，当三个部分中的任意一个出现问题，隧道就不可用。例如下图中，当客户端网络出现问题无法与服务端建立隧道连接，或者访问点无法连通服务，其对应的隧道也就无法访问。

![Tunnel SPOF](/images/tunnel-spof.png)

解决单点故障比较成熟的方案是，让系统的每个部分都可以做到水平扩展。通过运行多个实例形成一个集群，当集群中的单个实例出现故障时，其他实例可以继续运作，从而实现整个系统的高可用。对于客户端和访问端的单点问题，可以简单的通过运行多个实例来解决。

![Tunnel HA](/images/tunnel-ha.png)

反向代理隧道中的单个隧道支持多个连接，通过运行多个客户端并指定相同的隧道ID。多个连接在隧道服务端构成一个连接池，服务端以轮询的方式使用这些连接，当检测到客户端的连接异常后会将此连接剔除连接池。访问端也可以通过运行多个访问点来提高可用性。

客户端和访问端是无状态的，因此可以很容易实现水平扩展。但是服务端却无法简单的做到，服务端需要维护每个隧道的状态，隧道本身并不能随着服务端的扩展而自动迁移或复制。

![Tunnel SPOF](/images/tunnel-spof2.png)

如上图运行了两个服务端实例，客户端连接到Server-1。此时如果访问端的请求发送到Server-2，由于Server-2中没有隧道的连接，因此路由失败。对于服务端需要一些额外的手段来实现扩展性。

## 服务注册和发现

服务端无法做到水平扩展的原因是，服务端实例之间是相互独立的，彼此无法感知到其他实例中隧道的信息。因此我们需要一种方法来让服务端共享所有的客户端隧道和连接信息。反向代理隧道服务中通过[服务注册和发现](/concepts/sd/)机制来达到此目的，但其内部并没有集成具体的服务注册和发现功能模块，而是通过插件的方式将功能开放出来，由用户自己选择实现方式。

![Tunnel SD](/images/tunnel-sd.png)

当客户端连接到隧道服务后，服务端会将此客户端的连接信息发送给插件(Register)，服务端会定期检查连接状态并向插件报告(Renew)以便维持连接信息的有效性。当客户端断开后，服务端也会报告插件(Deregister)。

当访问端的请求到达服务端后，服务端首先在其自身的连接池中获取隧道的连接，如果没有找到则会再次向插件查询(Get)，插件会返回对应隧道的连接列表。其中每个连接信息中包含此连接所在的服务节点地址(入口点)，服务端最终将请求转发给其他实例处理。

## 云原生部署示例

当系统的所有部分都可以水平扩展后，就可以借助于Kubernetes等云原生平台来灵活部署。下面是一个完整的高可用反向代理隧道系统部署示例，其中Ingress路由和服务发现的插件部分均采用redis服务提供支持。

客户端通过`gost.local`域名连接隧道服务：

```bash
gost -L file://:8000 -L rtcp://:0/:8000 -F tunnel+ws://gost.local:80?tunnel.id=381433e1-7980-11ee-bbdb-60f262c1e32d
```

然后就可以通过`http://b7de88a94729b931.gost.local`来访问。


??? example "deploy.yaml"

    ```yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: tunnel
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: redis
      namespace: tunnel
    spec:
      selector:
        app: redis
      ports:
        - name: tcp
          protocol: TCP
          port: 6379
          targetPort: tcp
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: gost-tunnel
      namespace: tunnel
    spec:
      selector:
        app: gost-tunnel
      ports:
        - name: tunnel
          protocol: TCP
          port: 8421
          targetPort: tunnel
        - name: entrypoint
          protocol: TCP
          port: 80
          targetPort: entrypoint
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: ingress-plugin
      namespace: tunnel
    spec:
      selector:
        app: ingress-plugin
      ports:
        - name: tcp
          protocol: TCP
          port: 8000
          targetPort: tcp
    --- 
    apiVersion: v1
    kind: Service
    metadata:
      name: sd-plugin
      namespace: tunnel
    spec:
      selector:
        app: sd-plugin
      ports:
        - name: tcp
          protocol: TCP
          port: 8000
          targetPort: tcp
    --- 
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: gost-tunnel
      namespace: tunnel
    data:
      gost.yaml: |
        services:
        - name: service-0
          addr: :8421
          handler:
            type: tunnel
            metadata:
              entrypoint: :80
              ingress: ingress-0
              sd: sd-0
          listener:
            type: ws
    
        ingresses:
        - name: ingress-0
          plugin:
            type: grpc
            addr: ingress-plugin:8000
        
        sds:
        - name: sd-0
          plugin:
            type: grpc
            addr: sd-plugin:8000
    
        log:
          level: debug
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: gost-tunnel
      namespace: tunnel
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: gost-tunnel
      template:
        metadata:
          name: gost-tunnel
          labels:
            app: gost-tunnel
        spec:
          containers:
            - name: gost
              image: gogost/gost
              ports:
                - name: tunnel
                  containerPort: 8421
                  protocol: TCP
                - name: entrypoint
                  containerPort: 80
                  protocol: TCP
              resources:
                limits:
                  cpu: 1000m
                  memory: 500Mi
                requests:
                  cpu: 100m
                  memory: 100Mi
              volumeMounts:
                - name: config
                  mountPath: /etc/gost
                  readOnly: true
          volumes:
            - name: config
              configMap:
                name: gost-tunnel
          restartPolicy: Always
      strategy:
        type: RollingUpdate
        rollingUpdate:
          maxUnavailable: 0
          maxSurge: 1
      minReadySeconds: 10
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: ingress-plugin
      namespace: tunnel
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: ingress-plugin
      template:
        metadata:
          name: ingress-plugin
          labels:
            app: ingress-plugin
        spec:
          containers:
            - name: plugin
              image: ginuerzh/gost-plugins
              args:
              - "ingress"
              - "--addr=:8000"
              - "--redis.addr=redis:6379"
              - "--redis.db=1"
              - "--redis.expiration=1h"
              - "--domain=gost.local"
              - "--log.level=debug"
              ports:
                - name: tcp
                  containerPort: 8000
                  protocol: TCP
              resources:
                limits:
                  cpu: 1000m
                  memory: 500Mi
                requests:
                  cpu: 100m
                  memory: 100Mi
          restartPolicy: Always
      strategy:
        type: RollingUpdate
        rollingUpdate:
          maxUnavailable: 0
          maxSurge: 1
      minReadySeconds: 10
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: sd-plugin
      namespace: tunnel
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: sd-plugin
      template:
        metadata:
          name: sd-plugin
          labels:
            app: sd-plugin
        spec:
          containers:
            - name: plugin
              image: ginuerzh/gost-plugins
              args:
              - "sd"
              - "--addr=:8000"
              - "--redis.addr=redis:6379"
              - "--redis.db=2"
              - "--redis.expiration=3m"
              - "--log.level=debug"
              ports:
                - name: tcp
                  containerPort: 8000
                  protocol: TCP
              resources:
                limits:
                  cpu: 1000m
                  memory: 500Mi
                requests:
                  cpu: 100m
                  memory: 100Mi
          restartPolicy: Always
      strategy:
        type: RollingUpdate
        rollingUpdate:
          maxUnavailable: 0
          maxSurge: 1
      minReadySeconds: 10
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: redis
      namespace: tunnel
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: redis
      template:
        metadata:
          name: redis
          labels:
            app: redis
        spec:
          restartPolicy: Always
          containers:
            - name: redis
              image: redis:7.2-alpine
              ports:
                - name: tcp
                  containerPort: 6379
                  protocol: TCP
              resources:
                limits:
                  cpu: 1000m
                  memory: 1000Mi
                requests:
                  cpu: 10m
                  memory: 100Mi
              livenessProbe:
                exec:
                  command:
                    - redis-cli
                    - ping
                initialDelaySeconds: 30
                timeoutSeconds: 5
                periodSeconds: 15
                successThreshold: 1
                failureThreshold: 3
              imagePullPolicy: IfNotPresent
    ---
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: tunnel
      namespace: tunnel
    spec:
      rules:
        - host: gost.local
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: gost-tunnel
                    port:
                      name: tunnel
        - host: '*.gost.local'
          http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: gost-tunnel
                    port:
                      name: entrypoint
    ```
    
    
    
    