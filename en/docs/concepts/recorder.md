# Data Recording

## Recorder

Recorder can be used to record specific data, by configuring and referencing different recorder types to record data to different targets.

```yaml
services:
- name: service-0
  addr: :8080
  recorders:
  - name: recorder-0
    record: recorder.service.router.dial.address
  handler:
    type: auto
  listener:
    type: tcp

recorders:
- name: recorder-0
  file:
    path: /path/to/recorder/file
    sep: "\n"
```

## Recorder Types

Currently supported recorder types are: file, TCP servie, HTTP service, redis.

### File

File recorder records data to the specified file.

```yaml
recorders:
- name: recorder-0
  file:
    path: /path/to/recorder/file
    sep: "\n"
```

`file.path` (string)
:    file path

`sep` (string)
:    Record separator. If set, this separator will be inserted between two records

### TCP Service

TCP recorder sends data to the specified TCP service.

```yaml
recorders:
- name: recorder-0
  tcp:
    addr: 192.168.1.1:1234
    timeout: 10s
```

`tcp.addr` (string)
:    TCP service address

`timeout` (duration)
:    Timeout for establishing a connection

### HTTP Service

HTTP recorder sends data to the specified HTTP service using the HTTP `POST` method. If HTTP returns status code `200`, the recording is considered successful.

```yaml
recorders:
- name: recorder-0
  http:
    url: http://192.168.1.1:80
    timeout: 10s
```

`http.url` (string)
:    HTTP URL address

`timeout` (duration)
:    Timeout for establishing a connection

### Redis

Redis recorder records data to the redis server.

```yaml
recorders:
- name: recorder-0
  redis:
    addr: 127.0.0.1:6379
    db: 1
    password: 123456
    key: gost:recorder:recorder-0
    type: set
```

`addr` (string, required)
:    redis server address

`db` (int, default=0)
:    database name 

`password` (string)
:    redis password

`key` (string, required)
:    redis key

`type` (string, default=set)
:    data type: Set(`set`), Sorted Set(`sset`), List(`list`).

## Recorder Usage

The list of recorders to use is specified via `service.recorders`.

```yaml
services:
- name: service-0
  addr: :8080
  recorders:
  - name: recorder-0
    record: recorder.service.router.dial.address
  - name: recorder-1
    record: recorder.service.router.dial.address.error
  handler:
    type: auto
  listener:
    type: tcp
```

`name` (string, required)
:    recorder name

`record` (string, required)
:    record object

### Record Object

Currently supported record objects are:

`recorder.service.client.address`
:    All client addresses accessing the service

`recorder.service.router.dial.address`
:   All visited destination addresses

`recorder.service.router.dial.address.error`
:   All destination addresses that failed to establish a connection

`recorder.service.handler.serial`
:    Serial port device communication data

## Plugin

Recorder can be configured to use an external [plugin](/en/concepts/plugin/) service, and authenticator will forward the request to the plugin server for processing. Other parameters are invalid when using plugin.

```yaml
recorders:
- name: recorder-0
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

