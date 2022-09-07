# Service

!!! tip "Everything as a Service"
    In GOST, the client and the server are relative, and the client itself is also a service. If a forwarding chain or forwarder is used, the node in it is regarded as the server.

Service is the fundamental module of GOST and the entrance to the GOST program. Both the server and the client are built on the basis of services.

A service consists of a listener as a data channel, a handler for data processing and an optional forwarder for port forwarding.

!!! tip "Dynamic configuration"
    Service supports dynamic configuration via [Web API](/en/tutorials/api/overview/).

## Workflow

When a service is running, the listener will listen on the specified port according to the configuration of the service and communicate using the specified protocol. After receiving the correct data, the listener establishes a data channel connection and hands this connection to the handler for use. The handler performs data communication according to the specified protocol, and after receiving the request from the client, obtains the target address. If a forwarder is used, the target address specified in the forwarder is used, and then the router is used to send the request to the target host.

!!! info "Router"
    Router is an abstract module inside the handler, which contains the forwarding chain, resolver, host mapper, etc., for request routing between the service and the target host.

## Service Mesh

Services and services are independent, and a link between services can be established through forwarding chains or forwarders to form a service mesh. Data can hop and transfer arbitrarily between services. Some additional functions can be realized by using the service network, such as load balancing, bypass, etc.