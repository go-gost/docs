---
template: blog.html
author: ginuerzh
author_gh_user: ginuerzh
read_time: 15min
publish_date: 2022-12-20 22:00
comments: true
---

[Traefik](https://traefik.io/traefik/)是类似于Nginx的反向代理工具，其云原生的特性使其在Docker和Kubernetes环境下使用起来非常方便。

这里假设你的域名为`gost.run`，每个服务使用单独的子域名来路由，也可以使用URI路径来路由。

## Docker

由于Traefik和GOST都支持Docker容器化，因此这里直接采用Docker Compose来进一步简化部署流程。

??? example "docker-compose.yaml"

    ```yaml
    version: '3'

    services:
      traefik:
        # The official v2 Traefik docker image
        image: traefik:v2.9.6
        restart: always
        # Enables the web UI and tells Traefik to listen to docker
        command: 
        - "--providers.docker"
        - "--entrypoints.web.address=:80"
        - "--entrypoints.websecure.address=:443"
        - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
        - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
        # - "--api.insecure=true"
        # - "--api.dashboard=true"
        # - "--log.level=INFO"
        # - "--log.format=json"
        # - "--accesslog"
        # - "--accesslog.format=json"
        # - "--accesslog.filters.statuscodes=400-600"
        ports:
        # The HTTP port
        - "80:80"
        # The HTTPS port
        - "443:443"
        # The Web UI (enabled by --api.insecure=true)
        # - "8080:8080"
        volumes:
        # So that Traefik can listen to the Docker events
        - "/var/run/docker.sock:/var/run/docker.sock:ro"
        labels:
        - "traefik.http.routers.dashboard.tls=true"
        - "traefik.http.routers.dashboard.rule=Host(`traefik.gost.run`)"
        - "traefik.http.services.dashboard.loadbalancer.server.port=8080"

      gost-ws: 
        image: gogost/gost
        restart: always
        command: "-L relay+ws://:8080"
        labels:
        - "traefik.http.routers.gost-ws.tls=true"
        - "traefik.http.routers.gost-ws.rule=Host(`ws.gost.run`)"
        - "traefik.http.services.gost-ws.loadbalancer.server.port=8080"

      gost-grpc: 
        image: gogost/gost
        restart: always
        command: "-L relay+grpc://:8080?grpcInsecure=true"
        labels:
        - "traefik.http.routers.gost-grpc.tls=true"
        - "traefik.http.routers.gost-grpc.rule=Host(`grpc.gost.run`)"
        - "traefik.http.services.gost-grpc.loadbalancer.server.port=8080"
        - "traefik.http.services.gost-grpc.loadbalancer.server.scheme=h2c"
    	
      gost-pht:
        image: gogost/gost
        restart: always
        command: "-L relay+pht://:8080"
        labels:
        - "traefik.http.routers.gost-pht.tls=true"
        - "traefik.http.routers.gost-pht.rule=Host(`pht.gost.run`)"
        - "traefik.http.services.gost-pht.loadbalancer.server.port=8080"

      watchtower:
        image: containrrr/watchtower:1.5.1
        restart: always
        volumes:
        - "/var/run/docker.sock:/var/run/docker.sock:ro"
        command: --interval 300
    ```

执行以下命令就可以一键部署完成：

```bash
docker-compose -f docker-compose.yml -p web up -d
```

以下为配置文件的详细说明。

### Traefik

`traefik`服务暴露80和443端口作为访问入口，并且将80端口重定向到443端口。

Traefik自带的有dashboard，可以通过`--api.insecure=true`和`--api.dashboard=true`选项开启，并通过相应的labels配置路由，这里通过`traefik.gost.run`来访问。

### GOST Websocket

`gost-ws`服务是一个采用[Websocket](https://gost.run/tutorials/protocols/ws/)作为数据通道的relay代理服务，监听在8080端口，通过`ws.gost.run`子域名进行路由。

这里之所以没有使用TLS加密的Websocket数据通道(wss)，是因为Traefik服务已经自动处理了。

另外服务的端口无需暴露出来即可访问。

### GOST gRPC

`gost-grpc`服务是一个采用[gRPC](https://gost.run/tutorials/protocols/grpc/)作为数据通道的relay代理服务，监听在8080端口，通过`grpc.gost.run`子域名进行路由。

与`gost-ws`服务类似，这里使用`grpcInsecure=true`选项使用明文传输，将TLS的处理工作交给了Traefik。

注意这里服务上的`labels`需要增加一项`traefik.http.services.gost-grpc.loadbalancer.server.scheme=h2c`以表明此服务为gRPC服务。

### GOST PHT

`gost-pht`服务是一个采用[PHT](https://gost.run/tutorials/protocols/pht/)作为数据通道的relay代理服务，监听在8080端口，通过`pht.gost.run`子域名进行路由。

### Watchtower

[Watchtower](https://containrrr.github.io/watchtower)是一个自动更新容器的工具，它会定期检查当前运行的容器镜像是否有更新，并自动拉取新的镜像运行新的容器来替换现有的旧容器。这里也可以不使用此服务。

## Kubernetes

由于Traefik是[k3s](https://k3s.io)默认的Ingress Controller，因此这里就以k3s环境为例，k3s的版本为v1.24.3+k3s1，对应的Traefik版本为v2.6.2(rancher/mirrored-library-traefik:2.6.2)。

??? example "deploy.yaml"

	```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: gost-ws
    spec:
      selector:
        app: gost-ws
      ports:
      - name: ws
        port: 8080
        targetPort: ws
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: gost-grpc
    spec:
      selector:
        app: gost-grpc
      ports:
      - name: grpc
        port: 8080
        targetPort: grpc
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: gost-pht
    spec:
      selector:
        app: gost-pht
      ports:
      - name: pht
        port: 8080
        targetPort: pht
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: gost-ws
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: gost-ws
      template:
        metadata:
          name: gost-ws
          labels:
            app: gost-ws
        spec:
          containers:
          - image: gogost/gost
            name: gost
            args: 
              - -L
              - relay+ws://:8080
            ports:
            - name: ws
              containerPort: 8080
              protocol: TCP
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: gost-grpc
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: gost-grpc
      template:
        metadata:
          name: gost-grpc
          labels:
            app: gost-grpc
        spec:
          containers:
          - image: gogost/gost
            name: gost
            args: 
              - -L
              - relay+grpc://:8080?grpcInsecure=true
            ports:
            - name: grpc
              containerPort: 8080
              protocol: TCP
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: gost-pht
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: gost-pht
      template:
        metadata:
          name: gost-pht
          labels:
            app: gost-pht
        spec:
          containers:
          - image: gogost/gost
            name: gost
            args: 
              - -L
              - relay+pht://:8080
            ports:
            - name: pht
              containerPort: 8080
              protocol: TCP
    ---
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: gost-ws
      annotations:
        kubernetes.io/ingress.class: traefik
        traefik.ingress.kubernetes.io/preserve-host: "true"
    spec:
      rules:
      - host: ws.gost.run
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: gost-ws
                port:
                  name: ws
    ---
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: gost-pht
      annotations:
        kubernetes.io/ingress.class: traefik
        traefik.ingress.kubernetes.io/preserve-host: "true"
    spec:
      rules:
      - host: pht.gost.run
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: gost-pht
                port:
                  name: pht
    ---
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: gost-grpc
      annotations:
        kubernetes.io/ingress.class: grpc
    spec:
      rules:
      - host: grpc.gost.run
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: gost-grpc
                port:
                  name: grpc
    ---
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: gost-grpc
    spec:
      entryPoints:
        - websecure
      routes:
        - kind: Rule
          match: Host(`grpc.gost.run`)
          priority: 11
          services:
            - name: gost-grpc
              passHostHeader: true
              port: 8080
              weight: 10
              scheme: h2c
	```

对于`gost-grpc`服务，其Ingress需要通过annotation `kubernetes.io/ingress.class: grpc`指定其Class为`grpc`，并使用Traefik特有的CRD `IngressRoute`来定义路由规则。

执行以下命令便可以部署了：

```bash
kubectl apply -f deploy.yaml
```

## Cloudflare CDN

之所以选择以上三种类型的数据通道，是因为这些通道可以被反向代理服务所代理(Traefik, Nginx)，另外这几个通道也可以配合CDN使用，例如Cloudflare，这样既可以使用免费的TLS证书，并让CDN自动管理证书，又可以隐藏自己的服务器地址。

对于Websocket通道，需要在Cloudflare的Network设置界面中启用Websockets协议，默认应该是已经启用。客户端可以通过以下命令建立连接：

```
gost -L :8080 -F relay+wss://ws.gost.run:443
```

对于gRPC通道，需要在Cloudflare的Network设置界面中开启gRPC协议。客户端可以通过以下命令建立连接：

```
gost -L :8080 -F relay+grpc://grpc.gost.run:443
```

对于PHT通道，可以直接使用，或者使用HTTP/3作为底层传输方式，需要在Cloudflare的Network设置界面中开启HTTP/3加速功能。客户端可以通过以下命令建立连接：

* 直接连接

```
gost -L :8080 -F relay+phts://pht.gost.run:443
```

* 通过HTTP/3加速

```
gost -L :8080 -F relay+h3://pht.gost.run:443
```

如果你没有自己的域名，也是可以通过[域名IP映射](https://gost.run/concepts/hosts/)来访问服务，假设你的服务器IP为192.168.1.2：

```
gost -L :8080 -F relay+wss://ws.gost.run:443?hosts=ws.gost.run:192.168.1.2
```