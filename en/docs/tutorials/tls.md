---
comments: true
---

# TLS

GOST has three types of TLS certificates: self-generated certificate, global certificate, and service-level certificate.

## Self-generated Certificate

GOST automatically generates a TLS certificate on every run, and if no certificate is specified, this certificate is used as the default.

### Customize Certificate Information

=== "CLI"

	Setting a global certificate is not currently supported in command line mode.

=== "File (YAML)"

    ```yaml
    tls:
      validity: 8760h
      commonName: gost.run
      organization: GOST
    ```

`validity` (duration, default=8760h)
:    Validity period.

`commonName` (string, default=gost.run)
:    Common Name.

`organization` (string, default=GOST)
:    Organization.

## Global Certificate

The global certificate uses the automatically generated certificate by default, or you can specify a custom certificate file through configuration.

=== "CLI"

	Setting a global certificate is not currently supported in command line mode.

=== "File (YAML)"

    ```yaml
	tls:
	  certFile: "cert.pem"
	  keyFile: "key.pem"
	  caFile: "ca.pem"
	```

!!! tip "Default Files)
	GOST will automatically load the `cert.pem`, `key.pem`, `ca.pem` files in the current working directory to initialize the global certificate.

## Service-level Certificate

The listeners and handlers of each service can set their own certificates separately, and the global certificate is used by default.

=== "CLI"

    ```bash
	gost -L http+tls://:8443?certFile=cert.pem&keyFile=key.pem&caFile=ca.pem
	```

=== "File (YAML)"

    ```yaml
	services:
    - name: service-0
      addr: :8443
      handler:
        type: http
      listener:
        type: tls
        tls:
          certFile: cert.pem
          keyFile: key.pem
          caFile: ca.pem
	```

## Client Settings

Clients can set certificates separately for dialers and connectors for each node.

=== "CLI"

	```bash
	gost -L http://:8080 -F tls://IP_OR_DOMAIN:8443?secure=true&serverName=www.example.com
	```
	
=== "File (YAML)"

	```yaml
	services:
	- name: service-0
	  addr: :8080
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
		  addr: 192.168.1.1:8443
		  connector:
			type: http
		  dialer:
			type: tls
			tls:
			  secure: true
			  serverName: www.example.com
	```

`caFile` (string)
:    CA certificate file path. Setting up a CA certificate will enable Certificate Pinning.

`secure` (bool, default=false)
:    Enable server certificate and domain name verification.

`serverName` (string)
:    If `secure` is set to true, you need to specify the server domain name through this option for domain name verification. By default, `IP_OR_DOMAIN` in the setting is used as the serverName.

## TLS Options

```yaml
services:
- name: service-0
  addr: :8443
  handler:
    type: http
  listener:
    type: tls
    tls:
      options:
        minVersion: VersionTLS12
        maxVersion: VersionTLS13
        cipherSuites:
        - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
		alpn:
		- h2
		- http/1.1
```

`minVersion` (string)
:    Minimum TLS Version, `VersionTLS10`, `VersionTLS11`, `VersionTLS12` or `VersionTLS13`.

`maxVersion` (string)
:    Maximum TLS Version, `VersionTLS10`, `VersionTLS11`, `VersionTLS12` or `VersionTLS13`.

`cipherSuites` (list)
:    Cipher Suites, See [Cipher Suites](https://pkg.go.dev/crypto/tls#pkg-constants) for more information.

`alpn` (list)
: ALPN list

## Mutual TLS authentication

If a CA certificate is set on the server, the client certificate will be verified, and the client must provide the certificate.

=== "CLI"

	```bash
	gost -L http://:8080 -F tls://IP_OR_DOMAIN:8443?certFile=cert.pem&keyFile=key.pem
	```
	
=== "File (YAML)"

	```yaml
	services:
	- name: service-0
	  addr: :8080
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
		  addr: 192.168.1.1:8443
		  connector:
			type: http
		  dialer:
			type: tls
			tls:
			  certFile: cert.pem
			  keyFile: key.pem
	```

!!! note 
    Certificate information set via the command line applies only to the listener or dialer.

## Reject Unknown SNI

:material-tag: 3.3.0

When a TLS-based listener receives a handshake with a missing, empty, or unrecognized SNI (Server Name Indication), GOST by default completes the handshake and presents its certificate. Enabling `rejectUnknownSNI` rejects such handshakes at the TLS handshake stage (via the `GetConfigForClient` callback), so no certificate is ever sent to the rejected client. This reduces service and certificate exposure and protects against active probing.

=== "CLI"

	```bash
	gost -L http+tls://:8443?rejectUnknownSNI=true&serverNames=example.com
	```

=== "File (YAML)"

	```yaml
	services:
	- name: service-0
	  addr: :8443
	  handler:
	    type: http
	  listener:
	    type: tls
	    tls:
	      rejectUnknownSNI: true
	      serverNames:
	      - example.com
	```

`rejectUnknownSNI` (bool, default=false)
:    Reject TLS handshakes with an unknown or empty SNI. Rejected connections are dropped during the handshake and receive no certificate.

`serverNames` (list)
:    The allowed SNI whitelist. When `rejectUnknownSNI` is enabled and this list is non-empty, any SNI not in the list (including an empty SNI) is rejected. When the list is empty and `rejectUnknownSNI` is enabled, only handshakes with a missing or empty SNI are rejected; any named SNI is allowed.

!!! note "Applicable listeners"
    This takes effect on all TLS-based listener types: `tls`, `mtls`, `ws`, `mws`, `http2`, `grpc`, `http3`.