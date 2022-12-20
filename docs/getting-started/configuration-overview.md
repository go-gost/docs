# 配置概述

!!! tip "建议"
    在使用配置文件前，建议先了解一下GOST中的一些基本概念和架构，对于理解配置文件会有很大帮助。

    可以随时在命令行模式下使用`-O`输出当前配置。
	
!!! note "默认配置文件"
    如果`-C`和`-L`参数都未指定，GOST会在以下位置寻找`gost.yml`或`gost.json`文件：当前工作目录，`/etc/gost/`，`$HOME/gost/`。如果存在则使用此文件作为配置文件。

GOST运行方式有两种：命令行直接运行，和通过配置文件运行。命令行方式可以满足大多数使用需求，例如简单的启动一个代理或转发服务。如果需要更加详细的配置，可以采用配置文件方式，配置文件支持yaml或json格式。

详细的配置说明请参考：

* [命令行参数说明](../reference/configuration/cmd.md)
* [配置文件说明](../reference/configuration/file.md)

命令行模式与配置文件之间存在一个转换关系，例如：

```
gost -L http://gost:gost@localhost:8080?foo=bar -F socks5+tls://gost:gost@192.168.1.1:8080?bar=baz
```

对应的配置文件：

=== "yaml格式"
	```yaml
	services:
	- name: service-0
	  addr: "localhost:8080"
	  handler:
		type: http
		chain: chain-0
		auth:
		  username: gost
		  password: gost
		metadata:
		  foo: bar
	  listener:
		type: tcp
		metadata:
		  foo: bar
	chains:
	- name: chain-0
	  hops:
	  - name: hop-0
		nodes:
		- name: node-0
		  addr: 192.168.1.1:8080
		  connector:
			type: socks5
			auth:
			  username: gost
			  password: gost
			metadata:
			  bar: baz
		  dialer:
			type: tls
			metadata:
			  bar: baz
	```
=== "json格式"
	```json
	{
	  "services": [
		{
		  "name": "service-0",
		  "addr": "localhost:8080",
		  "handler": {
			"type": "http",
			"chain": "chain-0",
			"auth": {
			  "username": "gost",
			  "password": "gost"
			},
			"metadata": {
			  "foo": "bar"
			}
		  },
		  "listener": {
			"type": "tcp",
			"metadata": {
			  "foo": "bar"
			}
		  }
		}
	  ],
	  "chains": [
		{
		  "name": "chain-0",
		  "hops": [
			{
			  "name": "hop-0",
			  "nodes": [
				{
				  "name": "node-0",
				  "addr": "192.168.1.1:8080",
				  "connector": {
					"type": "socks5",
					"auth": {
					  "username": "gost",
					  "password": "gost"
					  },
					"metadata": {
					  "bar": "baz"
					}
				  },
				  "dialer": {
					"type": "tls",
					"metadata": {
					  "bar": "baz"
					}
				  }
				}
			  ]
			}
		  ]
		}
	  ]
	}
	```

- 所有`-L`参数会按顺序转换为`services`列表，每个service会自动生成名称`name`属性。

    * scheme部分会被解析为`handler`和`listener`，例如`http`会被转换为http处理器和tcp监听器。
    * 地址`localhost:8080`部分对应service的`addr`属性。
    * 认证信息`gost:gost`部分被转换为`handler.auth`属性。
	* 参数选项部分`foo=bar`被转换为`handler.metadata`和`listener.metadata`
	* 如果存在转发链，则使用`handler.chain`属性引用此转发链(通过`name`属性)。

- 如果有`-F`参数，则在`chains`列表中生成一条转发链，一个`-F`对应转发链的`hops`列表中的一项，`-F`参数按顺序转换为对应hop中的node。

    * scheme部分会被解析为`connector`和`dialer`，例如`socks5+tls`被转换为socks5连接器和tls拨号器。
    * 地址`192.168.1.1:8080`部分对应node的`addr`属性。
    * 认证信息`gost:gost`部分被转换为`connector.auth`属性。
	* 参数选项部分`foo=bar`被转换为`connector.metadata`和`dialer.metadata`
