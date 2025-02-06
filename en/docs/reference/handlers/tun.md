# TUN

Name: `tun`

状态： GA

=== "命令行"

    ```
	gost -L tun://:8421?net=192.168.123.2/24
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8421"
	  handler:
		type: tun
		metadata:
		  bufferSize: 1500
		  keepAlive: true
		  ttl: 10s
	  listener:
		type: tun
		metadata:
		  net: 192.168.123.2/24
	```

## Options

`bufferSize` (int, default=1500)
:    read buffer size in byte.

`keepAlive` (bool, default=false)
:    enable keepalive, valid for client.

`ttl` (duration, default=10s)
:    keepalive period, valid when `keepAlive` is true.

!!! note "限制"
    TUN处理器只能与[TUN监听器](/reference/listeners/tun/)一起使用，构建基于TUN设备的VPN。