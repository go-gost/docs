# Unix Domain Socket Remote Forwarding

Name: `runix`

Status: Stable

The RUNIX handler forwards data to the specified target Unix domain socket based on the forwarder configuration in the service.

=== "CLI"
    ```bash
    gost -L runix://./app.sock/var/run/remote.sock
    ```
=== "File (YAML)"
    ```yaml
    services:
    - name: service-0
      addr: "./app.sock"
      handler:
        type: runix
      listener:
        type: runix
      forwarder:
        nodes:
        - name: target-0
          addr: /var/run/remote.sock
    ```

## Parameters

None

!!! note "Limitations"
    The RUNIX handler can only be used together with the [runix listener](/reference/listeners/runix/) to build a Unix domain socket remote forwarding service.

