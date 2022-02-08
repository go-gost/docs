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
	```

具体请参考[在线API文档](https://latest.gost.run/swagger-ui/?url=https://latest.gost.run/swagger.yaml)