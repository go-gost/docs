# Web API

GOST can use the RESTful API to interact with the GOST process by starting the Web API service.

=== "CLI"
    ```sh
	gost -L http://:8080 -api :18080
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
	  pathPrefix: /api
	  accesslog: true
	  auth:
	    username: user
		password: pass
	  auther: auther-0
	```

You can even only open the API service, and then dynamically configure the service and other components through the API.

=== "CLI"
    ```sh
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
## Path Prefix

The URL path prefix can be set via the `pathPrefix` property.

For example, the default path is http://localhost:18080/config, when `pathPrefix` is set to `/api`, it becomes http://localhost:18080/api/config.

## Access Log

Use the `accesslog` property to enable the API access log. By default, no access log is output.

## Authentication

Authentication information can be set through the `auth` or `auther` property. If the `auther` property is set, the `auth` property is ignored.

Authentication uses [HTTP Basic Auth](https://en.wikipedia.org/wiki/Basic_access_authentication).

## Online Test

You can use [online environment](https://gost.run/play/webapi/config) to test, or try it directly in swaggerUI below. For API documentation, please refer to [API Documentation](/swagger-ui/).

The GOST program has built-in swagger API documentation. If the Web API service is enabled locally, you can also use [https://gost.run/swagger-ui/?url=http://localhost:18080/docs/swagger.yaml]( /swagger-ui/?url=http://localhost:18080/docs/swagger.yaml) to try to configure the local service (this assumes that the local Web API service is running on port 18080).

!!! note "Switch Scheme"
	The default scheme in SwaggerUI is HTTPS. If you want to test local services, you need to manually switch to HTTP.