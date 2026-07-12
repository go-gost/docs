---
authors:
  - ginuerzh
categories:
  - General
readtime: 1
date: 2015-05-21
comments: true
---

# GOST - GO Simple Tunnel

Original post: [https://groups.google.com/g/go-gost/c/vKbJh1IPK7o](https://groups.google.com/g/go-gost/c/vKbJh1IPK7o).

<!-- more -->

## A Secure Tunnel Implemented in Go

### Features

1. Supports setting an upstream HTTP proxy.
2. The client can act as an HTTP(s) or SOCKS5 proxy.
3. The server is compatible with the standard SOCKS5 protocol and can be used directly as a SOCKS5 proxy, with additional negotiated encryption.
4. Tunnel UDP over TCP — UDP packets are transmitted through TCP channels to bypass firewall restrictions.
5. Multiple encryption methods (TLS, AES-256-CFB, DES-CFB, RC4-MD5, etc.).
6. The client is compatible with the Shadowsocks protocol and can act as a Shadowsocks server.

Download binaries: [https://bintray.com/ginuerzh/gost/gost/view](https://bintray.com/ginuerzh/gost/gost/view).
