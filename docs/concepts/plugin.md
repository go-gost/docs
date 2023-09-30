# 插件系统

GOST的插件系统建立在gRPC或HTTP通讯基础之上，通过插件可以将处理逻辑转发给插件服务处理，从而可以对功能进行更灵活的扩展。

使用gRPC或HTTP通讯方式而不是动态链接库有以下几个优点：

* 支持多种语言，一个插件就是一个gRPC或HTTP服务，可以使用任何语言实现。
* 部署灵活，可以选择分开独立部署。
* 插件服务的生命周期不会影响到GOST本身。
* 安全，采用网络通讯方式，可以更有效的限制应用之间的数据共享。


目前支持插件的模块有：[跳跃点](/concepts/hop/) [准入控制器](/concepts/admission/)，[认证器](/concepts/auth/)，[分流器](/concepts/bypass/)，[主机IP映射器](/concepts/hosts/)，[域名解析器](/concepts/resolver/)，[Ingress](/concepts/ingress/)，[数据记录器](/concepts/recorder/)。

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
    type: grpc
	# type: http
    addr: 127.0.0.1:8000
	token: gost
    tls: {}
```

`type` (string, default=grpc)
:    插件类型，`grpc`或`http`

`addr` (string, required)
:    插件服务地址

`token` (string)
:    认证信息，作为服务认证机制，插件服务可以选择对此信息进行验证。

`tls` (duration, default=null)
:    设置后将使用TLS加密传输，默认不使用TLS加密。

## 编写插件

使用Go语言编写一个认证器插件服务。

### gRPC插件服务

[https://github.com/go-gost/plugin/blob/master/auth/example/grpc/main.go](https://github.com/go-gost/plugin/blob/master/auth/example/grpc/main.go)


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
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

var (
	port = flag.Int("port", 8000, "The server port")
)

type server struct {
	proto.UnimplementedAuthenticatorServer
}

func (s *server) Authenticate(ctx context.Context, in *proto.AuthenticateRequest) (*proto.AuthenticateReply, error) {
	// optional client authentication
	token := s.getCredentials(ctx)
	if token != "gost" {
		return nil, status.Error(codes.Unauthenticated, codes.Unauthenticated.String())
	}

	reply := &proto.AuthenticateReply{}
	if in.GetUsername() == "gost" && in.GetPassword() == "gost" {
		reply.Ok = true
	}
	return reply, nil
}

func (s *server) getCredentials(ctx context.Context) string {
	md, ok := metadata.FromIncomingContext(ctx)
	if ok && len(md["token"]) > 0 {
		return md["token"][0]
	}
	return ""
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

### HTTP插件服务

[https://github.com/go-gost/plugin/blob/master/auth/example/http/main.go](https://github.com/go-gost/plugin/blob/master/auth/example/http/main.go)

```go
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
)

var (
	port = flag.Int("port", 8000, "The server port")
)

type autherRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type autherResponse struct {
	OK bool   `json:"ok"`
	ID string `json:"id"`
}

func main() {
	flag.Parse()
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	log.Printf("server listening at %v", lis.Addr())

	http.HandleFunc("/auth", func(w http.ResponseWriter, r *http.Request) {
		rb := autherRequest{}
		if err := json.NewDecoder(r.Body).Decode(&rb); err != nil {
			log.Println(err)
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		resp := autherResponse{}
		if rb.Username == "gost" && rb.Password == "gost" {
			resp.OK = true
			resp.ID = "gost"
		}

		log.Printf("auth: %s, %s, %v", rb.Username, rb.Password, resp.OK)

		json.NewEncoder(w).Encode(resp)
	})

	if err := http.Serve(lis, nil); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
```