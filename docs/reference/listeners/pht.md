# Plain HTTP Tunnel

监听器名称: `pht`

状态： Alpha

PHT监听器根据服务配置，监听在指定TCP端口，并使用HTTP协议进行数据传输。

=== "命令行"
    ```
	gost -L http+pht://:8080
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
	  listener:
		type: pht
	```

## 参数列表

`backlog` (int, default=128)
:    请求队列大小

`authorizePath` (string, default=/authorize)
:    用户授权接口URI

`pushPath` (string, default=/push)
:    数据发送URI

`pullPath` (string, default=/pull)
:   数据接收URI
