# TLS

GOST有三种类型TLS证书：自生成证书，全局证书，服务层级证书。

## 自生成证书

GOST在每次运行时自动生成TLS证书，如果未指定任何证书，会使用此证书作为默认证书。

## 全局证书

全局证书默认使用自动生成的证书，也可以通过配置指定自定义证书文件。

=== "命令行"

    命令行模式下暂不支持设置全局证书。

=== "配置文件"

    ```yaml
	tls:
	  cert: "cert.pem"
	  key: "key.pem"
	  ca: "root.ca"
	```

	`cert`
	:    公钥文件路径

	`key`
	:    私钥文件路径

	`ca`
	:    CA证书文件路径

!!! tip "提示"
    GOST会自动加载当前工作目录下的`cert.pem`, `key.pem`, `ca.pem`文件来初始化全局证书。

## 服务层级证书

每个服务的监听器和处理器可以分别设置各自的证书，默认使用全局证书。

=== "命令行"

    ```
	gost -L http+tls://:8443?cert=cert.pem&key=key.pem&ca=ca.pem
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
          cert: cert.pem
          key: key.pem
          ca: ca.pem
	```

## 客户端设置

客户端可以对每个节点的拨号器和连接器分别设置证书。

=== "命令行"

	```
	gost -L http://:8080 -F tls://IP_OR_DOMAIN:8443?secure=true&serverName=www.example.com
	```
	
	`ca`
	:    CA证书文件路径。设置CA证书将会开启证书锁定(Certificate Pinning)。

	`secure`
	:    开启服务器证书和域名校验。默认值: false

	`serverName`
	:    若`secure`设置为true，则需要通过此参数指定服务器域名用于域名校验。
         默认使用设置中`IP_OR_DOMAIN`作为serverName。

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

## 双向证书校验

如果服务端设置了CA证书，则会对客户端证书进行强制校验，此时客户端须提供证书。

=== "命令行"

	```
	gost -L http://:8080 -F tls://IP_OR_DOMAIN:8443?cert=cert.pem&key=key.pem
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
			  cert: cert.pem
			  key: key.pem
	```

!!! note "注意"
	通过命令行设置的证书信息仅会应用到监听器或拨号器上。

    GOST会将命令行中的`cert`, `key`, `ca`, `secure`, `serverName`参数提取出来设置到`listener.tls`或`dialer.tls`中，
	如果通过命令行自动生成配置文件，在metadata中不会出现这些参数项。