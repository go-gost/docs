# Rate Limiting

!!! tip "Dynamic configuration"
    Limiter supports dynamic configuration via [Web API](/en/tutorials/api/overview/).

## Limiter

Requests can be limited by setting a Limiter on each service. The current Limiter supports the limit on the rate of input and output traffic, including three levels: service, connection and IP, the three levels can be used in combination.

=== "CLI"

    ```
    gost -L ":8080?limiter.rate.in=100MB&limiter.rate.out=100MB&limiter.rate.conn.in=10MB&limiter.rate.conn.out=10MB"
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
	  limiter: limiter-0
      handler:
        type: auto
      listener:
        type: tcp
    limiters:
    - name: limiter-0
	  rate:
	    limits:
		- '$ 100MB 100MB'
		- '$$ 10MB'
		- '192.168.1.1  512KB 1MB'
		- '192.168.0.0/16  1MB  5MB'
    ```

The service-level rate limit is set through `limiter.rate.in` and `limiter.rate.out` on the command line, and the connection-level is set through `limiter.rate.conn.in` and `limiter.rate.conn.out` level speed limit.

Use the `limiter` parameter in the configuration file to use the specified limiter by referencing the limiter name (`limiters.name`).

A list of configurations is specified via the `rate.limits` option, each configuration item consists of three parts separated by spaces:

* Scope: Limit scope, IP address or CIDR, such as 192.168.1.1, 192.168.0.0/16. There are two special values: `$` for service level and `$$` for connection level.

* Input: The rate at which the service receives data (per second). The supported units are: B, KB, MB, GB, TB, such as 128KB, 1MB, 10GB.

* Output: The rate at which the service sends data (per second), in the same unit as the input rate. The output rate is optional, if not set, it means unlimited.

## Data Source

The limiter can configure multiple data sources, currently supported data sources are: inline, file, redis.


### Inline

An inline data source means setting the data directly in the configuration file via the `rate.limits` option.

```yaml
limiters:
- name: limiter-0
  rate:
    limits:
	- $ 100MB  200MB
	- $$ 10MB
	- 192.168.1.1  1MB 10MB
	- 192.168.0.0/16  512KB  1MB
```

### File

Specify an external file as the data source. Specify the file path via the `rate.file.path` option.

```yaml
limiters:
- name: limiter-0
  rate:
	file:
      path: /path/to/file
```

The file format is a list of speed limit configurations separated by lines. The part starting with `#` is the comment information. The format of each line is the same as the inline configuration.

```yaml
# ip/cidr  input  output

$ 100MB  200MB
$$ 10MB
192.168.1.1  1MB 10MB
192.168.0.0/16  512KB  1MB
```

### Redis

Specify the redis service as the data source, and the redis data type must be Set or List. The format of each item is the same as the inline configuration. 

```yaml
limiters:
- name: limiter-0
  rate:
    redis:
      addr: 127.0.0.1:6379
      db: 1
      password: 123456
      key: gost:limiters:limiter-0
	  type: set
```

`addr` (string, required)
:    redis server address.

`db` (int, default=0)
:    database name.

`password` (string)
:    password

`key` (string, default=gost)
:    redis key

`type` (string, default=set)
:    redis data type: `set`, `list`

## Priority

When configuring multiple data sources at the same time, the priority from high to low is: redis, file, inline. If the same scop exists in different data sources, the data with higher priority will overwrite the data with lower priority.

## Hot Reload

File and redis data sources support hot reloading. Enable hot loading by setting the `rate.reload` property, which specifies the period for synchronizing the data source data.

```yaml
limiters:
- name: limiter-0
  rate:
    reload: 60s
    file:
      path: /path/to/file
    redis:
      addr: 127.0.0.1:6379
	  db: 1
	  password: 123456
	  key: gost:limiters:limiter-0
```
