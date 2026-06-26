# Shadowsocks

名称: `ss`

状态： Stable

SS处理器使用Shadowsocks协议进行数据交互，接收并处理客户端请求。

GOST对shadowsocks的支持是基于[shadowsocks/shadowsocks-go](https://github.com/shadowsocks/shadowsocks-go)和[shadowsocks/go-shadowsocks2](https://github.com/shadowsocks/go-shadowsocks2)库。

!!! tip "可选加密"
    Shadowsocks的加密是可选的，当不设置加密信息时，采用明文传输。如果需要显式使用无加密模式，可以指定 `none` 密码（详见下方 `none` / `dummy` 密码模式）。

=== "命令行"
    ```
	gost -L ss://AEAD_CHACHA20_POLY1305:123456@:8338
	```
=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8338"
	  handler:
		type: ss
		auth:
		  username: AEAD_CHACHA20_POLY1305
		  password: "123456"
	  listener:
		type: tcp
	```

## 参数列表

`readTimeout` (duration)
:    请求数据读取超时时长

!!! note "`none` / `dummy` 密码模式 (v3.3.0+)"
    GOST 支持 `none` 和 `dummy` 密码模式（大小写不敏感），用于调试、测试和兼容性场景。此模式使用标准的 SS AEAD 协议帧格式（2字节长度前缀 + salt + 目标地址），但不进行实际的数据加密。

    === "命令行（TCP）"
        ```
        gost -L "ss://none@:8338"
        ```
        ```
        gost -L ":8080" -F "ss://none@proxy.example.com:8338"
        ```

    === "命令行（UDP）"
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
    SS理器只能使用单认证信息方式设置加密信息，不能支持认证器。