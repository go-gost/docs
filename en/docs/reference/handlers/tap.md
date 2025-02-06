# TAP

Name: `tap`

Status： GA

=== "CLI"
    ```
	gost -L tap://:8421?net=192.168.123.2/24
	```
=== "File (YAML)"
    ```yaml
	services:
	- name: service-0
	  addr: ":8421"
	  handler:
		type: tap
		metadata:
		  bufferSize: 1500
	  listener:
		type: tap
		metadata:
		  net: 192.168.123.2/24
	```

## 参数列表

`bufferSize` (int, default=1500)
:   数据读写缓冲区字节大小 

!!! note "限制"
    TAP处理器只能与[TAP监听器](/reference/listeners/tap/)一起使用，构建基于TAP设备的VPN。