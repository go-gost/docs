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

    ```
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

	```
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

	```
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