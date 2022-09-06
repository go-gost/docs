# Authentication

Authentication can be performed by setting single authentication information or authenticator.

!!! tip "Dynamic configuration"
    Authenticator supports dynamic configuration via Web API.

## Single Authentication

If multi-user authentication is not required, single-user authentication can be performed by directly setting the single authentication information.

### Server

=== "CLI"

	Set directly by `username:password`:

    ```sh
	gost -L http://user:pass@:8080
	```

	If the authentication information contains special characters, it can also be set through the `auth` option. The value of `auth` is a base64 encoded value in the form of `username:password`.

	```sh
	echo -n user:pass | base64
	```

	```sh
	gost -L http://:8080?auth=dXNlcjpwYXNz
	```

=== "File (YAML)"

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
		auth:
		  username: user
		  password: pass
	  listener:
		type: tcp
	```

	Single authentication information is set via the `auth` property on the service's handler or listener.

### Client

=== "CLI"

	Set directly by `username:password`:

    ```
	gost -L http://:8080 -F socks5://user:pass@:1080
	```

	If the authentication information contains special characters, it can also be set through the `auth` option. The value of `auth` is a base64 encoded value in the form of `username:password`.

	```
	gost -L http://:8080 -F socks5://:1080?auth=dXNlcjpwYXNz
	```

=== "File (YAML)"

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
		nodes:
		- name: node-0
		  addr: :1080
		  connector:
			type: socks5
			auth:
			  username: user
			  password: pass
		  dialer:
		    type: tcp
	```

	Single authentication information is set via the `auth` property on the node's connector or dialer.

## Authenticator

An authenticator contains one or more sets of authentication information. Service can achieve the multi-user authentication function through the authenticator.

!!! note 
    Authenticator only supports the configuration file method.

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: http
		auther: auther-0
      listener:
        type: tcp
	authers:
	- name: auther-0
	  auths:
	  - username: user1
	    password: pass1
	  - username: user2
        password: pass2
	```

Use the specified authenticator by referencing the authenticator name via the `auther` property on the service's handler or listener.

!!! caution "Priority"
	If an authenticator is used, single authentication information will be ignored.

	If the `auth` option is set, the authentication information set directly in the path will be ignored.

!!! caution "Shadowsocks Handler"
	The Shadowsocks handler cannot use authenticator, and only supports setting single authentication information as encryption parameter.

## Authenticator Group

Use multiple authenticators by specifying a list of authenticators using the `authers` option. When any one of the authenticators passes the authentication, it means the authentication is passed.

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      handler:
        type: http
		authers:
		- auther-0
		- auther-1
      listener:
        type: tcp
	authers:
	- name: auther-0
	  auths:
	  - username: user1
	    password: pass1
	- name: auther-1
	  auths:
	  - username: user2
        password: pass2
	```

## Data Source

Authenticator can configure multiple data sources, currently supported data sources are: inline, file, redis.

### Inline

An inline data source means setting the data directly in the configuration file via the `auths` property.

```yaml
authers:
- name: auther-0
  auths:
  - username: user1
    password: pass1
  - username: user2
    password: pass2
```

### File

Specify an external file as the data source. Specify the file path via the `file.path` property.

```yaml
authers:
- name: auther-0
  file:
    path: /path/to/auth/file
```

The file format is the authentication information separated by lines, each line of authentication information is a user-pass pair separated by spaces, and the lines starting with `#` are commented out.

```yaml
# username password

admin           #123456
test\user001    123456
test.user@002   12345678
```

### Redis

Specify the redis service as the data source, and the redis data type must be [Hash](https://redis.io/docs/manual/data-types/#hashes).

```yaml
authers:
- name: auther-0
  redis:
    addr: 127.0.0.1:6379
	db: 1
	password: 123456
	key: gost:authers:auther-0
```

`addr` (string, required)
:    redis server address

`db` (int, default=0)
:    database name

`password` (string)
:    password

`key` (string, default=gost)
:    redis key

## Priority

When configuring multiple data sources at the same time, the priority from high to low is: redis, file, inline. If the same username exists in different data sources, the data with higher priority will overwrite the data with lower priority.

## Hot Reload

File and redis data sources support hot reloading. Enable hot loading by setting the `reload` property, which specifies the period for synchronizing the data source data.

```yaml
authers:
- name: auther-0
  reload: 10s
  file:
    path: /path/to/auth/file
  redis:
    addr: 127.0.0.1:6379
	db: 1
	password: 123456
	key: gost:authers:auther-0
```

!!! note 
	Authentication information set via the command line applies only to the handler or connector, and for ssh and sshd services it applies to the listener and dialer.

	If the configuration file is automatically generated through the command line, this parameter item will not appear in the metadata.
