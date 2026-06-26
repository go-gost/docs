# Shadowsocks UDP Relay

名称: `ssu`

状态： Stable

ssu处理器使用Shadowsocks UDP转发协议进行数据交互，用于转发UDP数据。

!!! tip "默认监听器"
    当不指定监听器时，SSU处理器默认使用UDP作为监听器。当然你也可以指定其他兼容类型的监听器(例如TCP, TLS等)。

=== "命令行"
    ```
	gost -L ssu://AEAD_CHACHA20_POLY1305:123456@:8338
	```
	等同于
	```
	gost -L ssu+udp://AEAD_CHACHA20_POLY1305:123456@:8338
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8338"
	  handler:
		type: ssu
		auth:
		  username: AEAD_CHACHA20_POLY1305
		  password: "123456"
	  listener:
		type: udp
	```

## 参数列表

`bufferSize` (int, default=1500)
:    UDP数据缓冲大小

!!! note "`none` / `dummy` 密码模式 (v3.3.0+)"
    GOST 支持 `none` 和 `dummy` 密码模式（大小写不敏感），用于调试、测试和兼容性场景。此模式使用标准的 SS AEAD 协议帧格式（2字节长度前缀 + salt + 目标地址），但不进行实际的 UDP 数据加密。

    === "命令行"
        ```
        gost -L "ssu://none@:8338"
        ```
        ```
        gost -L ":8080" -F "ssu://none@proxy.example.com:8338"
        ```

    === "配置文件"
        ```yaml
        auth:
          username: none
          password: ""
        ```

    !!! warning "安全提示"
        `none` / `dummy` 模式不提供任何数据机密性和完整性保护。仅用于调试、测试和兼容性场景，切勿在生产环境中使用。

!!! note "认证信息"
    SSU理器只能使用单认证信息方式设置加密信息，不能支持认证器。