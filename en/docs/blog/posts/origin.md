---
authors:
  - ginuerzh
categories:
  - General
readtime: 5
date: 2015-10-26
comments: true
---

# The Origin of GOST and Its Use Cases

Original post: [https://groups.google.com/g/go-gost/c/Cnh_4aeRVcg](https://groups.google.com/g/go-gost/c/Cnh_4aeRVcg).

The idea for gost came about in 2013, which was also my first year at the current company. Upon joining, I found that the company's network restrictions were extreme: the only way to access the internet was through the corporate proxy, and without applying for higher privileges, you could only visit Baidu search — all other websites were blocked. Since our team was working on mobile internet, daily development and research were quite inconvenient.

<!-- more -->

At the time, we had a Linode VPS for development, and the company had granted HTTP access to certain ports on this VPS. So I started thinking about using Linode as a relay.

The requirement was simple: establish a tunnel between the local machine and Linode through the company's proxy.

I searched online but couldn't find an existing solution (or perhaps I just missed it). Most tools worked only with direct connections and couldn't operate behind a proxy. So I started writing my own. The first version is at: [https://github.com/ginuerzh/goproxy](https://github.com/ginuerzh/goproxy). It was very simple, using HTTP polling, which made it inefficient, but it barely met the requirements — I could finally access the internet.

Soon after, I discovered that the company had also opened port 443 on Linode and supported HTTP CONNECT requests. This meant I could establish persistent connections for better efficiency. I immediately wrote a second version: [https://github.com/ginuerzh/gohttptun2](https://github.com/ginuerzh/gohttptun2). This version was already quite similar to what gost is today, though still relatively primitive.

This second version served me well for a long time and was quite stable, so I stopped updating it. Later, I discovered [c9.io](https://c9.io), which could relay data through WebSocket, and that's when gost was born.

Many people came to know gost through c9.io, but gost wasn't specifically designed for c9.io environments. As mentioned above, it's best suited for multi-hop forwarding scenarios, even if such scenarios are relatively uncommon.
