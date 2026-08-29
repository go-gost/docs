# UDP端口转发

名称: `udp`

状态： Stable

UDP处理器仅做纯UDP数据转发工作。根据服务中的转发器配置，将数据转发给指定的目标主机。

=== "命令行"
	```bash
	gost -L udp://:10053/:53
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: :10053
	  handler:
		type: udp
	  listener:
		type: udp 
	  forwarder:
	    nodes:
		- name: target-0
		  addr: :53
	```

## 参数列表

`stateless` (bool, default=false)
:    无状态UDP转发模式。启用后每个UDP数据报独立转发为一次请求-响应周期，不做会话跟踪，类似NGINX Stream模块的转发行为。启用时需要同时为[UDP监听器](/reference/listeners/udp/)设置`stateless: true`。


