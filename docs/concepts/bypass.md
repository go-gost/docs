# 分流

!!! tip "动态配置"
    分流器支持通过WebAPI进行动态配置。

## 分流器

在转发链中可以对每个节点设置分流器，在数据转发过程中，根据节点分流器中的规则来决定是否继续转发。

=== "命令行"
	```
	gost -L http://:8080 -F http://192.168.1.1:8080?bypass=172.10.0.0/16,127.0.0.1,localhost,*.example.com,.example.org
	```

	通过`bypass`参数来指定请求的目标地址匹配规则列表(以逗号分割的IP,CIDR,域名或域名通配符)。

=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: http
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        # hop level
        bypass: bypass-0
        nodes:
        - name: node-0
          addr: 192.168.1.1:8080
          # node level
          # bypass: bypass-0
          connector:
            type: http
          dialer:
            type: tcp
    bypasses:
    - name: bypass-0
      matchers:
      - 172.10.0.0/16
      - 127.0.0.1
      - localhost
      - '*.example.com'
      - .example.org
	```

	节点中使用`bypass`属性通过引用分流器名称(name)来使用指定的分流器。

!!! tip "Hop级别的分流器"
    bypass可以设置在hop或node上，如果node上未设置则使用hop上指定的bypass。

    命令行模式下的bypass参数配置会应用到hop级别。

## 黑名单与白名单

分流器默认为黑名单模式，当执行转发链的节点选择时，每当确定一个层级节点后，会应用此节点上的分流器，若请求的目标地址与分流器中的规则相匹配，则转发链终止于此节点(且不包含此节点)。

也可以将分流器设置为白名单模式，与黑名单相反，只有目标地址与分流器中的规则相匹配，才继续进行下一层级的节点选择。

=== "命令行"
	```
	gost -L http://:8080 -F http://192.168.1.1:8080?bypass=~172.10.0.0/16,127.0.0.1,localhost,*.example.com,.example.org
	```

	通过在`bypass`参数中增加`~`前缀将分流器设置为白名单模式。

=== "配置文件"
    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: http
        chain: chain-0
      listener:
        type: tcp
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        bypass: bypass-0
        nodes:
        - name: node-0
          addr: 192.168.1.1:8080
          # bypass: bypass-0
          connector:
            type: http
          dialer:
            type: tcp
    bypasses:
    - name: bypass-0
      reverse: true
      matchers:
      - 172.10.0.0/16
      - 127.0.0.1
      - localhost
      - '*.example.com'
      - .example.org
	```

	在`bypasses`中通过设置`reverse`属性为`true`来开启白名单模式。