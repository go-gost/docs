# MASQUE

Name: `masque`

Status: Alpha

The MASQUE connector uses the MASQUE protocol (RFC 9298 CONNECT-UDP) for UDP data forwarding. This connector only supports UDP and must be used together with the [H3-MASQUE dialer](/reference/dialers/h3-masque/).

!!! note "Limitations"
    The MASQUE connector must be used together with the [H3-MASQUE dialer](/reference/dialers/h3-masque/) to build a UDP proxy service based on the MASQUE protocol (RFC 9298).

=== "CLI"
    ```
		gost -L :8080 -F masque+h3-masque://:8443
		```

=== "File (YAML)"
    ```yaml
		services:
		- name: service-0
		  addr: ":8080"
		  handler:
			type: auto
			chain: chain-0
		  listener:
			type: tcp
		chains:
		- name: chain-0
		  hops:
		  - name: hop-0
			nodes:
			- name: node-0
			  addr: :8443
			  connector:
				type: masque
			  dialer:
				type: h3-masque
		```

## Parameters

`connectTimeout` (duration)
:    Connection timeout. Can be specified via `timeout` or `connectTimeout`.
