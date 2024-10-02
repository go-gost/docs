---
comments: true
---

# 认证

GOST中可以通过设置单认证信息或认证器进行简单的身份认证。

!!! tip "动态配置"
    认证器支持通过[Web API](/tutorials/api/overview/)进行动态配置。

## 单认证信息

如果不需要多用户认证，则可以通过直接设置单认证信息来进行单用户认证。

### 服务端

=== "命令行"

	直接通过`username:password`方式设置

    ```sh
	gost -L http://user:pass@:8080
	```
	如果认证信息中包含特殊字符，也可以通过`auth`参数来设置，`auth`的值为`username:password`形式的base64编码值。
	```sh
	echo -n user:pass | base64
	```

	```sh
	gost -L http://:8080?auth=dXNlcjpwYXNz
	```

=== "配置文件"

    ```yaml hl_lines="6 7 8"
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
		auth:
		  username: user
		  password: pass
	  listener:
		type: tcp
	```

    服务的处理器或监听器上通过`auth`属性设置单认证信息。

### 客户端

=== "命令行"

	直接通过`username:password`方式设置

    ```
	gost -L http://:8080 -F socks5://user:pass@:1080
	```
	如果认证信息中包含特殊字符，也可以通过`auth`参数来设置，`auth`的值为`username:password`形式的base64编码值。

	```
	gost -L http://:8080 -F socks5://:1080?auth=dXNlcjpwYXNz
	```

=== "配置文件"

    ```yaml hl_lines="18 19 20"
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
		  addr: :1080
		  connector:
			type: socks5
			auth:
			  username: user
			  password: pass
		  dialer:
		    type: tcp
	```
	节点的连接器或拨号器上通过`auth`属性设置单认证信息。

## 认证器

认证器包含一组或多组认证信息。服务通过认证器可以实现多用户认证功能。

!!! note
    认证器仅支持配置文件设置。

=== "配置文件"

    ```yaml hl_lines="6 10"
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
      auths:
      - username: user1
        password: pass1
      - username: user2
        password: pass2
	```

服务的处理器或监听器上通过`auther`属性引用认证器名称(name)来使用指定的认证器。

## 认证器组

通过使用`authers`属性来指定认证器列表来使用多个认证器，当任何一个认证器验证通过则代表认证通过。

=== "配置文件"

    ```yaml hl_lines="6 7 8 12 16"
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: http
		authers:
		- auther-0
		- auther-1
      listener:
        type: tcp
	authers:
	- name: auther-0
	  auths:
	  - username: user1
	    password: pass1
	- name: auther-1
	  auths:
	  - username: user2
        password: pass2
	```

!!! caution "优先级"
    如果使用了认证器，则单认证信息会被忽略。

	如果设置了`auth`参数，则路径中直接设置的认证信息会被忽略。

!!! caution "Shadowsocks处理器"
    Shadowsocks处理器无法使用认证器，仅支持通过设置单认证信息作为加密参数。

## 数据源

认证器可以配置多个数据源，目前支持的数据源有：内联，文件，redis，HTTP。

### 内联

内联数据源直接在配置文件中通过`auths`参数设置数据。

```yaml
authers:
- name: auther-0
  auths:
  - username: user1
    password: pass1
  - username: user2
    password: pass2
```

### 文件

指定外部文件作为数据源。通过`file.path`参数指定文件路径。

```yaml
authers:
- name: auther-0
  file:
    path: /path/to/file
```

文件格式为按行分割的认证信息，每一行认证信息为用空格分割的user-pass对，以`#`开始的行为注释行。

```text
# username password

admin           #123456
test\user001    123456
test.user@002   12345678
```

### Redis

指定redis服务作为数据源，redis数据类型必须为[哈希(Hash)](https://redis.io/docs/data-types/hashes/)类型。

```yaml
authers:
- name: auther-0
  redis:
    addr: 127.0.0.1:6379
    db: 1
    username: user
    password: 123456
    key: gost:authers:auther-0
```

`addr` (string, required)
:    redis服务地址

`db` (int, default=0)
:    数据库名

`username` (string)
:    用户名

`password` (string)
:    密码

`key` (string, default=gost)
:    redis key

数据的每一项与文件数据源的格式类似：

```redis
> HGETALL gost:authers:auther-0
1) "admin"
2) "#123456"
3) "test\user001"
4) "123456"
```

### HTTP

指定HTTP服务作为数据源。对于所请求的URL，HTTP返回200状态码则认为有效，返回的数据格式与文件数据源相同。

```yaml
authers:
- name: auther-0
  http:
    url: http://127.0.0.1:8000
    timeout: 10s
```

`url` (string, required)
:    请求的URL

`timeout` (duration, default=0)
:    请求超时时长

## 优先级

当同时配置多个数据源时，优先级从高到低为: HTTP，redis，文件，内联。如果在不同数据源中存在相同的用户名，则优先级高的会覆盖优先级低的数据。

## 热加载

文件，redis和HTTP数据源支持热加载。通过设置`reload`参数开启热加载，`reload`参数指定同步数据源数据的周期。

```yaml hl_lines="3"
authers:
- name: auther-0
  reload: 10s
  file:
    path: /path/to/file
  redis:
    addr: 127.0.0.1:6379
	db: 1
	password: 123456
	key: gost:authers:auther-0
  http:
    url: http://127.0.0.1:8000
    timeout: 10s
```

!!! note "注意"
	通过命令行设置的认证信息仅会应用到处理器或连接器上，对于ssh和sshd服务则会应用到监听器和拨号器上。

	如果通过命令行自动生成配置文件，在metadata中不会出现此参数项。

## 插件

认证器可以配置为使用外部[插件](/concepts/plugin/)服务，认证器会将认证请求转发给插件服务处理。当使用插件时其他参数无效。

```yaml
authers:
- name: auther-0
  plugin:
    type: grpc
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

`type` (string, default=grpc)
:    插件类型：`grpc`, `http`。

`addr` (string, required)
:    插件服务地址。

`tls` (object, default=null)
:    设置后将使用TLS加密传输，默认不使用TLS加密。

### HTTP插件

```yaml
authers:
- name: auther-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/auth
```

#### 请求示例

```bash
curl -XPOST http://127.0.0.1:8000/auth -d '{"username":"gost", "password":"gost", "client":"127.0.0.1:12345"}'
```

```json
{"ok": true, "id":"gost"}
```

`client` (string)
:    客户端地址

`id` (string)
:    插件服务可选择性返回的用户ID标识，此信息会传递给后续的其他插件服务(分流器，主机IP映射器，域名解析器，限制器等)用于用户身份标识。