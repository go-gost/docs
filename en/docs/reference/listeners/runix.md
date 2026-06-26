# Unix Domain Socket Remote Forwarding

Name: `runix`

Status: Stable

The RUNIX listener, based on the service configuration, listens on a Unix domain socket on a remote host (via a forwarding chain) and forwards accepted connections back to the local side.

## Without Forwarding Chain

=== "CLI"
    ```
    gost -L=runix://./app.sock
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
          addr: /var/run/app.sock
    ```

## With Forwarding Chain

=== "CLI"
    ```
    gost -L=runix://./app.sock/var/run/remote.sock -F relay://192.168.1.2:8421
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
        chain: chain-0
      forwarder:
        nodes:
        - name: target-0
          addr: /var/run/remote.sock
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: 192.168.1.2:8421
          connector:
            type: relay
          dialer:
            type: tcp
    ```

## Use Cases

The RUNIX listener is suitable for exposing a remote Unix domain socket service locally through a GOST forwarding chain. For example:

- Expose a remote Docker daemon (`/var/run/docker.sock`) locally through a forwarding chain
- Forward a remote MySQL database's Unix domain socket to the local machine
- Forward a remote HTTP service's Unix domain socket to the local machine

## Parameters

None

!!! note "Limitations"
    The RUNIX listener can only be used together with the [RUNIX handler](/reference/handlers/runix/) to build a Unix domain socket remote forwarding service.

!!! note "Note"
    Unix domain socket paths are paths on the filesystem. When using a forwarding chain, the target address must be a Unix domain socket path (e.g. `/var/run/app.sock`).
    The last hop of the forwarding chain must support Unix domain socket binding (e.g. using a relay connector).
