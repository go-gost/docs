# TUN/TAP Device

## TUN

TUN is based on [wireguard-go](https://git.zx2c4.com/wireguard-go).

!!! note "Windows"
    You need to download a platform-specific `wintun.dll` file from [wintun](https://www.wintun.net/), and put it side-by-side with gost.

### Usage

```
gost -L="tun://[method:password@][local_ip]:port[/remote_ip:port]?net=192.168.123.2/24&name=tun0&mtu=1350&route=10.100.0.0/16&gw=192.168.123.1"
```

`local_ip:port` (string, required)
:    Local UDP tunnel listen address.

`remote_ip:port` (string)
:    Remote UDP server address, IP packets received by the local TUN device will be forwarded to the remote server via UDP tunnel.

`net` (string, required)
:    CIDR IP address of the TUN device, such as: 192.168.123.1/24.

`name` (string)
:    TUN device name.

`mtu` (int, default=1350)
:    MTU for TUN device.

`gw` (string)
:    Default routing gateway.

`route` (string)
:    Comma-separated routing table, such as: 10.100.0.0/16,172.20.1.0/24,1.2.3.4/32.

`routes` (list)
:    Gateway-specific routing, Each entry in the list is a space-separated CIDR address and gateway, such as `10.100.0.0/16 192.168.123.2`

`bufferSize` (int, default=1500)
:    read buffer size in byte.

`keepAlive` (bool, default=false)
:    enable keepalive, valid for client.

`ttl` (duration, default=10s)
:    keepalive period, valid when `keepAlive` is true.

`passphrase` (string)
:     Client authentication code, up to 16 characters, only valid for the client.


### Example

#### Server

=== "CLI"

    ```
    gost -L=tun://:8421?net=192.168.123.1/24
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
        metadata:
          bufferSize: 1500
      listener:
        type: tun
        metadata:
          name: tun0
          net: 192.168.123.1/24
          mtu: 1350
    ```
#### Client

=== "CLI"

    ```
    gost -L=tun://:0/SERVER_IP:8421?net=192.168.123.2/24
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
        metadata:
          bufferSize: 1500
          keepAlive: true
          ttl: 10s
      listener:
        type: tun
        metadata:
          net: 192.168.123.2/24
      forwarder:
	      nodes:
        - name: target-0
		      addr: SERVER_IP:8421
    ```

### Server Side Routing

The server can access the client network by setting up routing table and gateway.

#### Default gateway

The server can set the default gateway through the `gw` option to specify the gateway of the routes in route parameter.

```
gost -L="tun://:8421?net=192.168.123.1/24&gw=192.168.123.2&route=172.10.0.0/16,10.138.0.0/16"
```

Packets send to network 172.10.0.0/16 and 10.138.0.0/16 will be forwarded to the client with the IP 192.168.123.2 through the TUN tunnel.

#### Gateway-specific routing

If you want to set a specific gateway for each route, you can specify it via `routes` option:

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
      listener:
        type: tun
        metadata:
          net: 192.168.123.1/24
          routes:
          - 72.10.0.0/16 192.168.123.2
          - 10.138.0.0/16 192.168.123.3
    ```
Packets send to network 172.10.0.0/16 will be forwarded to the client with the IP 192.168.123.2 through the TUN tunnel.

Packets send to network 10.138.0.0/16 will be forwarded to the client with the IP 192.168.123.3 through the TUN tunnel.

### Authentication

The server can use [Auther](/en/concepts/auth/) to authenticate the client.

#### Server

```yaml hl_lines="6"
services:
- name: service-0
  addr: :8421
  handler:
    type: tun
    auther: tun
  listener:
    type: tun
    metadata:
      net: 192.168.123.1/24

authers:
- name: tun
  auths:
  - username: 192.168.123.2
    password: userpass1
  - username: 192.168.123.3
    password: userpass2
```

The username of the auther is the IP assigned to the client.


#### Client

=== "CLI"

    ```
    gost -L "tun://:0/SERVER_IP:8421?net=192.168.123.2/24&passphrase=userpass1"
    ```

=== "File (YAML)"

    ```yaml hl_lines="10"
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
        metadata:
          bufferSize: 1500
          keepAlive: true
          ttl: 10s
          passphrase: "userpass1"
      listener:
        type: tun
        metadata:
          net: 192.168.123.2/24
      forwarder:
        nodes:
        - name: target-0
          addr: SERVER_IP:8421
    ```

The client specifies the authentication code via the `passphrase` option.

!!! tip "Authentication and Heartbeat"
    When using authentication, it is recommended that the client enable heartbeat, and the authentication information will be sent to the server in the heartbeat packet. When the server restarts, the heartbeat packet will restore the connection.

!!! note "Passphrase Length Limitation"
    The passphrase supports up to 16 characters. When the client exceeds this length limit, only the first 16 characters are used.

!!! caution "Secure Transmission"
    The data of the TUN tunnel is transmitted in clear text, including authentication information. Data transmission can be made more secure by utilizing encrypted tunnels using forwarding chains.

### TUN-based VPN (Linux)

!!! tip
    The value specified by `net` option may need to be adjusted according to your actual situation.

#### Create a TUN Device and Establish a UDP Tunnel

##### Server

=== "CLI"

    ```
    gost -L=tun://:8421?net=192.168.123.1/24
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
      listener:
        type: tun
        metadata:
          net: 192.168.123.1/24
    ```
##### Client

=== "CLI"

    ```
    gost -L=tun://:0/SERVER_IP:8421?net=192.168.123.2/24
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
      listener:
        type: tun
        metadata:
          net: 192.168.123.2/24
      forwarder:
	      nodes:
        - name: target-0
		      addr: SERVER_IP:8421
    ```


When no error occurred, you can use the `ip addr` command to inspect the created TUN device:

```
$ ip addr show tun0
2: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1350 qdisc pfifo_fast state UNKNOWN group default qlen 500
    link/none 
    inet 192.168.123.2/24 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::d521:ad59:87d0:53e4/64 scope link flags 800 
       valid_lft forever preferred_lft forever
```

Now you can `ping` the server address:

```
$ ping 192.168.123.1
64 bytes from 192.168.123.1: icmp_seq=1 ttl=64 time=9.12 ms
64 bytes from 192.168.123.1: icmp_seq=2 ttl=64 time=10.3 ms
64 bytes from 192.168.123.1: icmp_seq=3 ttl=64 time=7.18 ms
```

#### iperf3 Testing

##### Server

```
$ iperf3 -s
```

##### Client

```
$ iperf3 -c 192.168.123.1
```

#### IP Routing and Firewall Rules

If you want the client to access the server network, you need to set the corresponding routing table and firewall rules according to your needs. For example, all the client external network traffic can be forwarded to the server.

##### Server

Enable IP forwarding and set up firewall rules

```
$ sysctl -w net.ipv4.ip_forward=1

$ iptables -t nat -A POSTROUTING -s 192.168.123.0/24 ! -o tun0 -j MASQUERADE
$ iptables -A FORWARD -i tun0 ! -o tun0 -j ACCEPT
$ iptables -A FORWARD -o tun0 -j ACCEPT
```

##### Client

Set up firewall rules

!!! caution
    The following operations will change the client's network environment, unless you know what you are doing, please be careful!

```
$ ip route add SERVER_IP/32 dev eth0   # replace the SERVER_IP and eth0
$ ip route del default   # delete the default route
$ ip route add default via 192.168.123.2  # add new default route
```

## TAP

TAP is based on [songgao/water](https://github.com/songgao/water).

!!! note "Windows"
    You need to install the tap driver [OpenVPN/tap-windows6](https://github.com/OpenVPN/tap-windows6) or [OpenVPN client](https://github.com/OpenVPN/openvpn) for Windows.


!!! note "Limitation"
    TAP devices are not supported by macOS.

### Usage

```
gost -L="tap://[local_ip]:port[/remote_ip:port]?net=192.168.123.2/24&name=tap0&mtu=1350&route=10.100.0.0/16&gw=192.168.123.1"
```

## TUN/TAP tunnel over TCP

The TUN/TAP tunnel in GOST is based on the UDP protocol by default.

If you want to use TCP, you can choose the following methods:

### Forward Chain

You can use chain to forward UDP data, analogous to UDP port forwarding.

This method is more flexible and general, and is recommended.

#### Server

=== "CLI"

    ```
    gost -L=tun://:8421?net=192.168.123.1/24 -L relay+wss://:8443?bind=true
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
      listener:
        type: tun
        metadata:
          net: 192.168.123.1/24
    - name: service-1
      addr: :8443
      handler:
        type: relay
        metadata:
          bind: true
      listener:
        type: wss
    ```
#### Client

=== "CLI"

    ```
    gost -L=tun://:0/:8421?net=192.168.123.2/24 -F relay+wss://SERVER_IP:8443
    ```

=== "File (YAML)"

    ```yaml
    services:
    - name: service-0
      addr: :8421
      handler:
        type: tun
        chain: chain-0
      listener:
        type: tun
        metadata:
          net: 192.168.123.1/24
      forwarder:
	      nodes:
        - name: target-0
		      addr: :8421
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: SERVER_IP:8443
          connector:
            type: relay
          dialer:
            type: wss
    ```
### Third-party tools

[udp2raw-tunnel](https://github.com/wangyu-/udp2raw-tunnel).