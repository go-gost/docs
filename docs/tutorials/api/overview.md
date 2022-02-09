# WebAPI

GOST可以通过开启WebAPI服务使用RESTful API和GOST进程进行交互。

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
	  addr: 18080
	  pathPrefix: /api
	  accesslog: true
	```

甚至可以只开启API服务，后续通过API来动态配置服务和其他组件。

=== "命令行"
    ```sh
	gost -api :18080
	```
=== "配置文件"
    ```yaml
	api:
	  addr: 18080
	  pathPrefix: /api
	  accesslog: true
	```

接口说明请参考[在线API文档](/swagger-ui/)。

你可以使用[线上环境](https://latest.gost.run/play/webapi/config)进行测试，或在上面的swagger UI中直接尝试。

GOST程序已经内置了swagger API文档，如果本地开启了WebAPI服务，也可以通过[https://latest.gost.run/swagger-ui/?url=http://localhost:18080/docs/swagger.yaml](https://latest.gost.run/swagger-ui/?url=http://localhost:18080/docs/swagger.yaml)来尝试配置本地服务(这里假设本地WebAPI服务运行在18080端口)。
