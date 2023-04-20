# Plugin System

Plugin system is based on gRPC communication. Through the plugin, the requests can be forwarded to the plugin server for processing, so that the function can be expanded more flexibly.

Using gRPC communication instead of dynamic link library has the following advantages:

* Support multiple languages. A plugin is a gRPC service, which can be implemented in any language.
* Deployment is flexible, and you can choose to deploy independently.
* The life cycle of the plugin will not affect the GOST itself.
* Security. Using network communication, can more effectively limit data sharing between applications.

The modules that currently support plugin are: [Admission](/en/concepts/admission/), [Authenticator](/en/concepts/auth/), [Bypass](/en/concepts/bypass/), [Host Mapper](/en/concepts/hosts/), [Resolver](/en/concepts/resolver/), [Ingress](/en/concepts/ingress/), [Recorder](/en/concepts/recorder/).

## Plugin Usage

Taking the authenticator as an example, after configuring the authenticator to use the plugin service, all authentication requests will be forwarded to the plugin server for processing.

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
	token: gost
    tls: {}
```

`addr` (string, required)
:    plugin server address.

`token` (string)
:    credentials, plugin server can choose to validate this information.

`tls` (duration, default=null)
:    After the configuration, TLS will be used to encrypt transmission. By default, TLS is not used.

## Plugin Service

Write an authenticator plugin service in Go language.

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

[https://github.com/go-gost/plugin/blob/master/auth/example/main.go](https://github.com/go-gost/plugin/blob/master/auth/example/main.go)