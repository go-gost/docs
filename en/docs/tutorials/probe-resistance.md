# 探测防御

GOST对HTTP/HTTPS/HTTP2代理提供了探测防御功能。当代理服务收到非法请求时，会按照探测防御策略返回对应的响应内容。

!!! note
    只有当代理服务开启了用户认证，探测防御功能才有效。

=== "命令行"
    ```
    gost -L=http://gost:gost@:8080?probeResistance=code:400&knock=www.example.com
    ```
=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: :8080
      handler:
        type: http
        auth:
          username: gost
          password: gost
        metadata:
          knock: www.example.com
          probeResistance: code:404
      listener:
        type: tcp
    ```
## probeResistance

代理服务通过`probeResistance`参数来指定防御策略。参数值的格式为：`type:value`。

type可选值有:

* `code` - 对应value为HTTP响应码，代理服务器会回复客户端指定的响应码。例如：
    ```
    gost -L=http://gost:gost@:8080?probeResistance=code:403
    ```

* `web` - 对应的value为URL，代理服务器会使用HTTP GET方式访问此URL，并将响应返回给客户端。例如: 
    ```
    gost -L=http://gost:gost@:8080?probeResistance=web:example.com/page.html
    ```

* `host` - 对应的value为主机地址，代理服务器会将客户端请求转发给设置的主机地址，并将主机的响应返回给客户端，代理服务器在这里相当于端口转发服务。例如：
	```
	gost -L=https://gost:gost@:443?probeResistance=host:www.example.com:8080
	```

* `file` - 对应的value为本地文件路径，代理服务器会回复客户端200响应码，并将指定的文件内容作为Body发送给客户端。例如：
	```
	gost -L=http2://gost:gost@:443?probeResistance=file:/send/to/client/file.txt
	```

## knock

开启了探测防御功能后，当认证失败时服务器默认不会响应`407 Proxy Authentication Required`，但某些情况下客户端需要服务器告知代理是否需要认证(例如Chrome中的SwitchyOmega插件)。通过`knock`参数设置一个私有地址，只有访问此地址时服务器才会发送`407`响应。