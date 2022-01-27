# HTTP/3

监听器名称: `http3`

状态： Experimental

HTTP3监听器根据服务配置，监听在指定UDP端口，并使用HTTP/3协议进行数据传输。

=== "命令行"
    ```
	gost -L http+http3://:8080
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
	  listener:
		type: http3
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

