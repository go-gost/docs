# Admission Control

!!! tip "Dynamic configuration"
    Admission Controller supports dynamic configuration via Web API.

## Admission Controller

An admission controller can be set on each service to control client access.

=== "CLI"
    ```
    gost -L http://:8080?admission=127.0.0.1,192.168.0.0/16
    ```
    Specify a list of client address matching rules (comma-separated IP or CIDR) via the `admission` option.

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

## Hot Reload

File and redis data sources support hot reloading. Enable hot loading by setting the `reload` property, which specifies the period for synchronizing the data source data.

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
