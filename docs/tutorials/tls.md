---
comments: true
---

# TLS

GOST有三种类型TLS证书：自生成证书，全局证书，服务层级证书。

## 自生成证书

GOST在每次运行时自动生成TLS证书，如果未指定任何证书，会使用此证书作为默认证书。

### 自定义证书信息

=== "命令行"

    命令行模式下暂不支持设置全局证书。

=== "配置文件"

    ```yaml
    tls:
      validity: 8760h
      commonName: gost.run
      organization: GOST
    ```

`validity` (duration, default=8760h)
:    证书有效期，默认1年。

`commonName` (string, default=gost.run)
:    证书CN信息。

`organization` (string, default=GOST)
:    证书的Organization信息。

## 全局证书

全局证书默认使用自动生成的证书，也可以通过配置指定自定义证书文件。

=== "命令行"

    命令行模式下暂不支持设置全局证书。

=== "配置文件"

    ```yaml
	tls:
	  certFile: "cert.pem"
	  keyFile: "key.pem"
	  caFile: "ca.pem"
	```

!!! tip "提示"
    GOST会自动加载当前工作目录下的`cert.pem`, `key.pem`, `ca.pem`文件来初始化全局证书。

## 服务层级证书

每个服务的监听器和处理器可以分别设置各自的证书，默认使用全局证书。

=== "命令行"

    ```bash
	gost -L http+tls://:8443?certFile=cert.pem&keyFile=key.pem&caFile=ca.pem
	```

=== "配置文件"

    ```yaml
    services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: tls
        tls:
          certFile: cert.pem
          keyFile: key.pem
          caFile: ca.pem
	```

## 客户端设置

客户端可以对每个节点的拨号器和连接器分别设置证书。

=== "命令行"

	```bash
	gost -L http://:8080 -F tls://IP_OR_DOMAIN:8443?secure=true&serverName=www.example.com
	```
	
=== "配置文件"

	```yaml
	services:
	- name: service-0
	  addr: :8080
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
		  addr: 192.168.1.1:8443
		  connector:
			type: http
		  dialer:
			type: tls
			tls:
			  secure: true
			  serverName: www.example.com
	```

`caFile` (string)
:    CA证书文件路径。设置CA证书将会开启证书锁定(Certificate Pinning)。

`secure` (bool, default=false)
:    开启服务器证书和域名校验。

`serverName` (string)
:    若`secure`设置为true，则需要通过此参数指定服务器域名用于域名校验。默认使用设置中`IP_OR_DOMAIN`作为serverName。

## TLS选项

```yaml
services:
- name: service-0
  addr: :8443
  handler:
    type: http
  listener:
    type: tls
    tls:
      options:
        minVersion: VersionTLS12
        maxVersion: VersionTLS13
        cipherSuites:
        - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
		alpn:
		- h2
		- http/1.1
```

`minVersion` (string)
:    TLS最小版本，可选值`VersionTLS10`，`VersionTLS11`，`VersionTLS12`，`VersionTLS13`。

`maxVersion` (string)
:    TLS最大版本，可选值`VersionTLS10`，`VersionTLS11`，`VersionTLS12`，`VersionTLS13`。

`cipherSuites` (list)
:    加密套件，可选值参考[Cipher Suites](https://pkg.go.dev/crypto/tls#pkg-constants)。

`alpn` (list)
:    APLN列表

## 双向证书校验

如果服务端设置了CA证书，则会对客户端证书进行强制校验，此时客户端须提供证书。

=== "命令行"

	```bash
	gost -L http://:8080 -F tls://IP_OR_DOMAIN:8443?certFile=cert.pem&keyFile=key.pem
	```
	
=== "配置文件"

	```yaml
	services:
	- name: service-0
	  addr: :8080
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
		  addr: 192.168.1.1:8443
		  connector:
			type: http
		  dialer:
			type: tls
			tls:
			  certFile: cert.pem
			  keyFile: key.pem
	```

!!! note "注意"
	通过命令行设置的证书信息仅会应用到监听器或拨号器上。


## 拒绝未知SNI

:material-tag: 3.3.0

当基于TLS的监听器收到缺少、为空或无法识别的SNI（Server Name Indication）握手请求时，GOST默认会完成握手并返回自身证书。开启`rejectUnknownSNI`后，GOST会在TLS握手阶段（通过`GetConfigForClient`回调）拒绝此类握手，被拒绝的客户端不会收到任何证书。这可以降低服务和证书的暴露面，并防止主动探测。

=== "命令行"

	```bash
	gost -L http+tls://:8443?rejectUnknownSNI=true&serverNames=example.com
	```

=== "配置文件"

	```yaml
	services:
	- name: service-0
	  addr: :8443
	  handler:
	    type: http
	  listener:
	    type: tls
	    tls:
	      rejectUnknownSNI: true
	      serverNames:
	      - example.com
	```

`rejectUnknownSNI` (bool, default=false)
:    拒绝SNI未知或为空的TLS握手。被拒绝的连接会在握手阶段直接断开，不会返回任何证书。

`serverNames` (list)
:    允许的SNI白名单。当`rejectUnknownSNI`开启且此列表非空时，任何不在列表中的SNI（包括空SNI）都会被拒绝；当列表为空且`rejectUnknownSNI`开启时，仅拒绝缺少或为空SNI的握手，其余任意命名SNI均允许通过。

!!! note "适用监听器"
	此功能对所有基于TLS的监听器类型生效：`tls`，`mtls`，`ws`，`mws`，`http2`，`grpc`，`http3`。