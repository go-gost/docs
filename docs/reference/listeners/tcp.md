# TCP

监听器名称: `tcp`

状态： Stable

TCP监听器根据服务配置，监听在指定TCP端口。

=== "命令行"
    ```
	gost -L http://:8080
	```
	等价于
	```
	gost -L http+tcp://:8080
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
	```

## 参数列表

无

!!! tip "提示"

    TCP监听器是GOST中默认的监听器，当不指定监听器类型时，默认使用此监听器。
