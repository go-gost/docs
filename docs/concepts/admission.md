# 准入控制

!!! tip "动态配置"
    准入控制器支持通过Web API进行动态配置。

## 准入控制器

在每个服务上可以分别设置一个准入控制器来控制客户端接入。

=== "命令行"
	```
	gost -L http://:8080?admission=127.0.0.1,192.168.0.0/16
	```

	通过`admission`参数来指定客户端地址匹配规则列表(以逗号分割的IP或CIDR)。

=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      admission: admission-0
      handler:
        type: http
      listener:
        type: tcp
    admissions:
    - name: admission-0
      matchers:
      - 127.0.0.1
      - 192.168.0.0/16
	```

	服务中使用`admission`属性通过引用准入控制器名称(name)来使用指定的准入控制器。

## 黑名单与白名单

与分流器类似，准入控制器也可以设置黑名单或白名单模式，默认为白名单模式。

=== "命令行"
	```
	gost -L http://:8080?admission=~127.0.0.1,192.168.0.0/16
	```

	通过在`admission`参数中增加`~`前缀将准入控制器设置为黑名单模式。

=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      admission: admission-0
      handler:
        type: http
      listener:
        type: tcp
    admissions:
    - name: admission-0
      reverse: true
      matchers:
      - 127.0.0.1
      - 192.168.0.0/16
	```

	在`admissions`中通过设置`reverse`属性为`true`来开启黑名单模式。