---
comments: true
---

# Probing Resistance

GOST provides probing resistance for the HTTP/HTTPS/HTTP2 proxies. When the proxy server receives an invalid request, it will return the corresponding response according to the probing resistance policy.

!!! note
    The probing resistance feature is only valid when the proxy server has user authentication enabled.

=== "CLI"

    ```bash
    gost -L=http://gost:gost@:8080?probeResist=code:400&knock=www.example.com
    ```
    
=== "File (YAML)"

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
          probeResist: code:404
      listener:
        type: tcp
    ```

## `probeResist` Option

The proxy server specifies the policy through the `probeResist` option. The format of the parameter is: `type:value`.

The optional values for type are:

* `code` - Corresponding value is HTTP response code. The proxy server will reply to client the specified status code. For example:
    ```
    gost -L=http://gost:gost@:8080?probeResist=code:403
    ```

* `web` - Corresponding value is HTTP URL. The proxy server will request this URL using HTTP GET method and return the response to the client. For example:
    ```
    gost -L=http://gost:gost@:8080?probeResist=web:example.com/page.html
    ```

* `host` - Corresponding value is host[:port]. The proxy server forwards the client request to the specified host and returns the host's response to the client. The proxy server is equivalent to the port forwarding service here. For example:
	```
	gost -L=https://gost:gost@:443?probeResist=host:www.example.com:8080
	```

* `file` - The corresponding value is the local file path. The proxy server will reply to the client 200 response code, and the content of the specified file is sent to the client as response Body. For example:
	```
	gost -L=http2://gost:gost@:443?probeResist=file:/send/to/client/file.txt
	```

## knock

After the probe resistance is enabled, the server will not respond the `407 Proxy Authentication` Required to the client by default when authentication fails. But in some cases the client needs the server to tell if it needs authentication (for example, the SwitchyOmega plugin in Chrome). Set a private host with the `knock` parameter, the server will only send a `407` response when accessing this host.