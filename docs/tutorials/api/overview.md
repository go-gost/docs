# Web API

GOST可以通过开启Web API服务使用RESTful API和GOST进程进行交互。

=== "命令行"

    ```sh
	gost -L http://:8080 -api :18080
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
	  pathPrefix: /api
	  accesslog: true
	  auth:
	    username: user
		password: pass
	  auther: auther-0
	```

甚至可以只开启API服务，后续通过API来动态配置服务和其他组件。

=== "命令行"

    ```sh
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

## 路径前缀

通过`pathPrefix`参数可以设置URL路径前缀。

例如默认路径为http://localhost:18080/config，当设置`pathPrefix`为`/api`后变为http://localhost:18080/api/config。

## 访问日志

通过`accesslog`参数开启接口访问日志，默认不输出访问日志。

## 身份认证

通过`auth`或`auther`参数可以设置身份认证信息。如果设置了`auther`参数，`auth`参数则会被忽略。身份认证采用[HTTP Basic Auth](https://en.wikipedia.org/wiki/Basic_access_authentication)方式。

```yaml
api:
  addr: :18080
  auth:
    username: user
    password: pass
  auther: auther-0
```

## 在线测试

你可以使用[线上环境](https://gost.run/play/webapi/config)进行测试，或在下面的swaggerUI中直接尝试。接口说明请参考[在线API文档](/swagger-ui/)。

GOST程序已经内置了swagger API文档，如果本地开启了Web API服务，也可以通过[https://gost.run/swagger-ui/?url=http://localhost:18080/docs/swagger.yaml](/swagger-ui/?url=http://localhost:18080/docs/swagger.yaml)来尝试配置本地服务(这里假设本地Web API服务运行在18080端口)。

!!! note "Scheme切换"
    SwaggerUI中默认的scheme为HTTPS，如果要测试本地服务则需要手动切换到HTTP。