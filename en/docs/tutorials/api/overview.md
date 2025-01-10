---
comments: true
---

# Web API

GOST can use the RESTful API to interact with the GOST process by starting the Web API service.

## Start API Service

The API service supports two modes: global service and normal service.

When using global service and reloading configuration using the web API, the service will not be affected.

### Global Service

Define the API service via the command line `-api` or the `api` object in the configuration file.

=== "CLI"

    ```bash
	gost -L http://:8080 -api :18080
	```

	or

	```bash
	gost -L http://:8080 -api "user:pass@:18080?pathPrefix=/api&accesslog=true"
	```

=== "File (YAML)"

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: http
	  listener:
		type: tcp
	api:
	  addr: :18080
	  # also support unix domain socket
	  # addr: unix:///var/run/gost.sock
	  pathPrefix: /api
	  accesslog: true
	  auth:
		username: user
		password: pass
	  auther: auther-0
	```

You can also start the API service only, and then dynamically configure services and other components through the API.

=== "CLI"

    ```bash
	gost -api :18080
	```

=== "File (YAML)"

    ```yaml
	api:
	  addr: :18080
	  pathPrefix: /api
	  accesslog: true
	  auth:
	    username: user
		password: pass
	  auther: auther-0
	```

### Normal Service

When running as a normal service, you can use all the functions supported by service.

=== "CLI"

    ```bash
	gost -L "api+tls://user:pass@:18080?pathPrefix=/api&accessLog=true"
	```

=== "File (YAML)"

    ```yaml
	services:
	- name: service-0
	  addr: ":18080"
	  handler:
		type: api
		auth:
		  username: user
		  password: pass
		metadata:
		  pathPrefix: /api
		  accessLog: true
	  listener:
		type: tls
	```

## Path Prefix

The URL path prefix can be set via the `pathPrefix` property.

For example, the default path is http://localhost:18080/config, when `pathPrefix` is set to `/api`, it becomes http://localhost:18080/api/config.

## Access Log

Use the `accesslog` property to enable the API access log. By default, no access log is output.

## Authentication

Authentication uses [HTTP Basic Auth](https://en.wikipedia.org/wiki/Basic_access_authentication).

Authentication information can be set through the `auth` or `auther` options. If the `auther` option is set, the `auth` option is ignored. 

=== "CLI"

    ```sh
	gost -api user:pass@:18080
	```

=== "File (YAML)"

    ```yaml
    api:
      addr: :18080
      auth:
        username: user
        password: pass
      auther: auther-0
    ```

## Online Test

You can use [online environment](https://api.gost.run/config) to test, or try it directly in swaggerUI below. For API documentation, please refer to [API Documentation](https://api.gost.run/swagger-ui/?url=/docs/swagger.yaml).

The GOST program has built-in swagger API documentation. If the Web API service is enabled locally, you can also use [https://api.gost.run/swagger-ui/?url=http://localhost:18080/docs/swagger.yaml](https://api.gost.run/swagger-ui/?url=http://localhost:18080/docs/swagger.yaml) to try to configure the local service (this assumes that the local Web API service is running on port 18080).

!!! note "Switch Scheme"
	The default scheme in SwaggerUI is HTTPS. If you want to test local services, you need to manually switch to HTTP.