---
comments: true
---

# Web API

GOST可以通过web API服务使用RESTful API和GOST进程进行交互。

## 开启服务

API服务支持两种运行方式：全局服务和普通服务。

当使用全局服务，采用web API方式进行配置重载时，服务将不受影响。

### 全局服务

通过命令行`-api`或配置文件中的`api`对象来定义API服务。

=== "命令行"

    ```bash
	gost -L http://:8080 -api :18080
	```

	开启认证并设置选项

	```bash
	gost -L http://:8080 -api "user:pass@:18080?pathPrefix=/api&accesslog=true"
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
	  listener:
		type: tcp
	api:
	  addr: :18080
	  # unix domain socket
	  # addr: unix:///var/run/gost.sock
	  pathPrefix: /api
	  accesslog: true
	  auth:
	    username: user
		password: pass
	  auther: auther-0
	```

也可以只开启API服务，后续通过API来动态配置服务和其他组件。

=== "命令行"

    ```bash
	gost -api :18080
	```

=== "配置文件"

    ```yaml
	api:
	  addr: :18080
	  pathPrefix: /api
	  accesslog: true
	  auth:
	    username: user
		password: pass
	  auther: auther-0
	```

### 普通服务

:material-tag: 3.1.0

采用普通服务运行时，可以使用服务所支持的所有功能。

=== "命令行"

    ```bash
	gost -L "api+tls://user:pass@:18080?pathPrefix=/api&accessLog=true"
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":18080"
	  handler:
		type: api
		auth:
		  username: user
		  password: pass
		metadata:
		  pathPrefix: /api
		  accessLog: true
	  listener:
		type: tls
	```

## 路径前缀

通过`pathPrefix`参数可以设置URL路径前缀。

例如默认路径为http://localhost:18080/config，当设置`pathPrefix`为`/api`后变为http://localhost:18080/api/config。

## 访问日志

通过`accesslog`参数开启接口访问日志，默认不输出访问日志。

## 身份认证

身份认证采用[HTTP Basic Auth](https://en.wikipedia.org/wiki/Basic_access_authentication)方式。

配置文件中通过`auth`或`auther`选项可以设置身份认证信息，如果设置了`auther`选项，`auth`选项则会被忽略。

=== "命令行"

    ```sh
	gost -api user:pass@:18080
	```

=== "配置文件"

    ```yaml
    api:
      addr: :18080
      auth:
        username: user
        password: pass
      auther: auther-0
    ```

## 在线测试

你可以使用[线上环境](https://api.gost.run/config)进行测试，或在下面的swaggerUI中直接尝试。接口说明请参考[在线API文档](https://api.gost.run/swagger-ui/?url=/docs/swagger.yaml)。

GOST程序已经内置了swagger API文档，如果本地开启了Web API服务，也可以通过[https://api.gost.run/swagger-ui/?url=http://localhost:18080/docs/swagger.yaml](https://api.gost.run/swagger-ui/?url=http://localhost:18080/docs/swagger.yaml)来尝试配置本地服务(这里假设本地Web API服务运行在18080端口)。

!!! note "Scheme切换"
    SwaggerUI中默认的scheme为HTTPS，如果要测试本地服务则需要手动切换到HTTP。