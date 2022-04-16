# Configuration Overview

!!! tip
    Before using the configuration file, it is recommended to understand some basic concepts and architecture, which will be very helpful for understanding the configuration file.

    You can use `-O` in command line mode to output the current configuration at any time.
	
There are two ways to run GOST: run directly in the command line, and run through a configuration file. The command-line mode is sufficient for most use cases, such as simply starting a proxy or forwarding service. If you need more elaborate configuration, you can use the configuration file. The configuration file supports `YAML` and `JSON` formats.

For detailed configuration specification, please refer to:

* [CLI](../reference/configuration/cmd.md)
* [File](../reference/configuration/file.md)

There is a conversion relationship between the command line mode and the configuration file, for example:

```
gost -L http://gost:gost@localhost:8080?foo=bar -F socks5+tls://gost:gost@192.168.1.1:8080?bar=baz
```

The corresponding configuration file:

=== "YAML"
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
=== "JSON"
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

- All `-L` parameters are converted to a list of `services` in order, each service will automatically generate a name `name` attribute.

    * The scheme will be parsed as `handler` and `listener`, for example `http` will be converted to http handler and tcp listener.
	* The `localhost:8080` corresponds to the field `addr` of the service.
    * The authentication `gost:gost` is converted to `handler.auth`.
	* The option `foo=bar` is converted to `handler.metadata`和`listener.metadata`.
	* If a forwarding chain exists, it is referenced by `handler.chain` (via the `name` field).

- If there are one or more `-F` parameters, a forwarding chain is generated in the `chains` list, a `-F` corresponds to an item in the `hops` list of the forwarding chain, and the `-F` parameters are converted in order to the nodes in the corresponding hop.

    * The scheme will be parsed as `connector` and `dialer`, for example `socks5+tls` will be converted to socks5 connector and tls dialer.
    * The `192.168.1.1:8080` corresponds to the node field `addr`.
    * The authentication `gost:gost` is converted to `connector.auth`.
	* The option `foo=bar` is converted to `connector.metadata` and `dialer.metadata`

!!! note "Default Configuration File"
    If neither `-C` nor `-L` parameters are specified, GOST will look for `gost.yml` or `gost.json` file in the following locations: current working directory, `/etc/gost/`, `$HOME/gost/`, and use it as the configuration file if it exists.
