# Overview

GOST mainly consists of four modules: Service, Node, Hop, Chain, and five sub-modules: Listener, Handler, Forwarder, Dialer and Connector, plus several auxiliary modules: Selector, Admission, Bypass, Resolver, Host Mapper, Limiter and other components.

## Service

The service is the entrance and exit of the data. The data of the client is received and processed by the service, and finally the processed data is sent back to the client.

Each service contains a Listener and a Handler.

## Node

A node is the general term for the services used by the forwarding chain from the perspective of the client, and the nodes in the forwarding chain can be regarded as the client corresponding to the service. Services other than the services run by the current program can be regarded as nodes (even the services started by the current program can be regarded as nodes), and are not limited to the services provided by the GOST program.

Each node contains a Dialer and a Connector.

## Hop

A hop is a set of nodes, which is an abstraction of the logical level of the forwarding chain. A chain of length 3 corresponds to 3 hops, and the data will be processed by a node in each hop in turn.

## Chain

A chain, a.k.a Forwarding Chain, is a hop group composed of several nodes in a certain order, a chain can consist of one or more hops. When forwarding data, a node will be selected from each hop according to the forwarding strategy (node selector, bypass), and finally a route will be formed, and the service will use this route for data forwarding.

## Listener

Listener opens the specified port locally. It is responsible for data transmission, data channel establishment and initialization (such as encryption and decryption, session and data stream channel initialization, etc.), and direct data interaction with the client.

## Handler

Handler is a logical abstraction layer of the listener. After the listener establishes a data channel, the client request data will be handed over to the handler for processing, including request routing, domain name resolution, permission control etc.

## Forwarder

Forwarder is used for port forwarding and is used by handler. The handler forwards each request data according to the node group and node selector configured by the forwarder.

## Dialer

Dialer corresponds to the listener of service and is responsible for data interaction with the service, establishment and initialization of the data channel.

## Connector

Connector is a logical abstraction layer of dialer, which corresponds to the handler of service. After the dialer and the service have established a data channel, the connector will process the actual requested data.