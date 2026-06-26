# Shadowsocks

Name: `ss`

Status： Stable

SS处理器使用Shadowsocks协议进行数据交互，接收并处理客户端请求。

GOST对shadowsocks的支持是基于[shadowsocks/shadowsocks-go](https://github.com/shadowsocks/shadowsocks-go)和[shadowsocks/go-shadowsocks2](https://github.com/shadowsocks/go-shadowsocks2)库。

!!! tip "Encryption"
    Shadowsocks encryption is optional. When no encryption parameters are set, plaintext transmission is used. To explicitly use no encryption while maintaining proper AEAD framing, use the `none` cipher (see below).

=== "CLI"
    ```
	gost -L ss://AEAD_CHACHA20_POLY1305:123456@:8338
	```
=== "File (YAML)"
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

!!! note "`none` / `dummy` Cipher Mode (v3.3.0+)"
    GOST supports `none` and `dummy` cipher modes (case-insensitive) for debugging, testing, and compatibility. This mode uses the standard SS AEAD wire framing (2-byte length prefix + salt + target address) without actual encryption.

    === "CLI (TCP)"
        ```
        gost -L "ss://none@:8338"
        ```
        ```
        gost -L ":8080" -F "ss://none@proxy.example.com:8338"
        ```

    === "CLI (UDP)"
        ```
        gost -L "ssu://none@:8338"
        ```
        ```
        gost -L ":8080" -F "ssu://none@proxy.example.com:8338"
        ```

    === "File (YAML)"
        ```yaml
        auth:
          username: none
          password: ""
        ```

    !!! warning "Security"
        The `none` / `dummy` mode provides zero confidentiality or integrity protection. It is intended for debugging and testing only — never use it in production.

!!! note "认证信息"
    SS理器只能使用单认证信息方式设置加密信息，不能支持认证器。