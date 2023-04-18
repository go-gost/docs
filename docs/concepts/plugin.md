# 插件系统

GOST的插件系统建立在gRPC通讯基础之上，通过插件可以将处理逻辑转发给插件服务处理，从而可以对功能进行更灵活的扩展。

使用gRPC通讯方式而不是动态链接库有以下几个优点：

* 支持多种语言，一个插件就是一个gRPC服务，可以使用任何语言实现。
* 部署灵活，可以选择分开独立部署。
* 插件服务的生命周期不会影响到GOST本身。
* 安全，采用网络通讯方式，可以更有效的限制应用之间的数据共享。


目前支持插件的模块有：[准入控制器](/concepts/admission/)，[认证器](/concepts/auth/)，[分流器](/concepts/bypass/)，[主机IP映射器](/concepts/hosts/)，[域名解析器](/concepts/resolver/)，[Ingress](/concepts/ingress/)，[数据记录器](/concepts/recorder/)。

## 使用插件

以认证器为例，当配置认证器使用插件服务后，所有的认证请求将转发给插件服务处理。

```yaml
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: http
        auther: auther-0
      listener:
        type: tcp
    authers:
    - name: auther-0
      plugin:
        addr: 127.0.0.1:8000
        tls: {}
```

## 编写插件

使用Go语言编写一个认证器插件服务。

```go
package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net"

	"github.com/go-gost/plugin/auth/proto"
	"google.golang.org/grpc"
)

var (
	port = flag.Int("port", 8000, "The server port")
)

type server struct {
	proto.UnimplementedAuthenticatorServer
}

func (s *server) Authenticate(ctx context.Context, in *proto.AuthenticateRequest) (*proto.AuthenticateReply, error) {
	reply := &proto.AuthenticateReply{}
	if in.GetUsername() == "gost" && in.GetPassword() == "gost" {
		reply.Ok = true
	}
	return reply, nil
}

func main() {
	flag.Parse()
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()
	proto.RegisterAuthenticatorServer(s, &server{})
	log.Printf("server listening at %v", lis.Addr())
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
```

[https://github.com/go-gost/plugin/blob/master/auth/example/main.go](https://github.com/go-gost/plugin/blob/master/auth/example/main.go)