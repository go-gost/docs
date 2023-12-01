---
comments: true
---

# Admission Control

!!! tip "Dynamic configuration"
    Admission Controller supports dynamic configuration via [Web API](/en/tutorials/api/overview/).

## Admission Controller

An admission controller can be set on each service to control client access.

=== "CLI"
    ```
    gost -L http://:8080?admission=127.0.0.1,192.168.0.0/16,example.com
    ```
    Specify a list of client address matching rules via the `admission` option, each rule is a comma-separated IP, CIDR, or domain, domain will be resolved to IP.

=== "File (YAML)"

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
      - example.com
    ```

    Use the `admission` property in the service to use the specified admission controller by referencing the admission controller name.

## Blacklist And Whitelist

Similar to the bypass, the admission controller can also set the blacklist or whitelist mode, the default is the blacklist mode.

=== "CLI"
    ```
    gost -L http://:8080?admission=~127.0.0.1,192.168.0.0/16
    ```

    Set the admission controller to whitelist mode by adding the `~` prefix to the `admission` option.

=== "File (YAML)"

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
      whitelist: true
      matchers:
      - 127.0.0.1
      - 192.168.0.0/16
    ```

    Enable blacklist mode in `admissions` by setting the `whitelist` property to `true`.

## Admission Control Group

Multiple controllers can be used by specifying a list of admission controllers using the `admissions` option. When any one of the controllers rejects, it means the rejection.

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: ":8080"
      admissions: 
      - admission-0
      - admission-1
      handler:
        type: http
      listener:
        type: tcp
    admissions:
    - name: admission-0
      whitelist: true
      matchers:
      - 192.168.0.0/16
      - 127.0.0.1
    - name: admission-1
      matchers:
      - 192.168.0.1
    ```

## Data Source

The admission controller can configure multiple data sources, currently supported data sources are: inline, file, redis.

### Inline

An inline data source means setting the data directly in the configuration file via the `matchers` property.

```yaml
admissions:
- name: admission-0
  matchers:
  - 127.0.0.1
  - 192.168.0.0/16
  - example.com
```

### File

Specify an external file as the data source. Specify the file path via the `file.path` property.

```yaml
admissions:
- name: admission-0
  file:
    path: /path/to/admission/file
```

The file format is a list of addresses separated by lines, and the part starting with `#` is the comment information.

```text
# ip or cidr

127.0.0.1
192.168.0.0/16
example.com
```

### Redis

Specify the redis service as the data source, and the redis data type must be [Set](https://redis.io/docs/manual/data-types/#sets).

```yaml
admissions:
- name: admission-0
  redis:
    addr: 127.0.0.1:6379
	db: 1
	password: 123456
	key: gost:admissions:admission-0
```

`addr` (string, required)
:    redis server address.

`db` (int, default=0)
:    database name.

`password` (string)
:    password

`key` (string, default=gost)
:    redis key

```redis
> SMEMBERS gost:admissions:admission-0
1) "127.0.0.1"
2) "192.168.0.0/16"
3) "example.com"
```

### HTTP

Specify the HTTP service as the data source. For the requested URL, if HTTP returns a 200 status code, it is considered valid, and the returned data format is the same as the file data source.

```yaml
admissions:
- name: admission-0
  http:
    url: http://127.0.0.1:8000
    timeout: 10s
```

`url` (string, required)
:    request URL

`timeout` (duration, default=0)
:    request timeout

## Hot Reload

File, redis and HTTP data sources support hot reloading. Enable hot loading by setting the `reload` property, which specifies the period for synchronizing the data source data.

```yaml
admissions:
- name: admission-0
  reload: 10s
  file:
    path: /path/to/auth/file
  redis:
    addr: 127.0.0.1:6379
	db: 1
	password: 123456
	key: gost:admissions:admission-0
```

## Plugin

The admission controller can be configured to use an external [plugin](/en/concepts/plugin/) service, and the controller will forward the request to the plugin server for processing. Other parameters are invalid when using plugin.

```yaml
admissions:
- name: admission-0
  plugin:
    addr: 127.0.0.1:8000
    tls: 
      secure: false
      serverName: example.com
```

`addr` (string, required)
:    plugin server address.

`tls` (duration, default=null)
:    TLS encryption will be used for transmission, TLS encryption is not used by default.

### HTTP Plugin

```yaml
admissions:
- name: admission-0
  plugin:
    type: http
    addr: http://127.0.0.1:8000/admission
```

#### Example

```bash
curl -XPOST http://127.0.0.1:8000/admission -d '{"addr": "example.com"}'
```

```json
{"ok": true}
```
