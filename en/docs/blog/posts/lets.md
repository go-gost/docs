---
authors:
  - ginuerzh
categories:
  - General
readtime: 5
date: 2015-12-18
comments: true
---

# Setting Up an HTTPS Proxy with Let's Encrypt and GOST

Original post: [https://groups.google.com/g/go-gost/c/32jXBP3pAxc](https://groups.google.com/g/go-gost/c/32jXBP3pAxc).

[Let's Encrypt](https://letsencrypt.org/) launched its public beta on December 3rd, meaning everyone can now have a free TLS certificate, provided the server is bound to a domain name.

<!-- more -->

First, generate the certificate:

```bash
git clone https://github.com/letsencrypt/letsencrypt.git
cd letsencrypt
letsencrypt-auto certonly --email your_email@email.com -d your_host_domain.com
```

If everything goes well, a `live` directory will be created under `/etc/letsencrypt/`, containing your domain directory and the certificate files.
We only need two files: **cert.pem** and **privkey.pem**.

With the certificates ready, you can now run the HTTPS proxy:

GOST has a built-in TLS certificate. To use your own certificate, place `cert.pem` and `key.pem` (key.pem is the privkey.pem from Let's Encrypt) in gost's working directory.

Assuming the gost binary is in `/home/abc`:

```bash
cd /home/abc
cp /etc/letsencrypt/live/your_host_domain.com/cert.pem /home/abc/cert.pem
cp /etc/letsencrypt/live/your_host_domain.com/privkey.pem /home/abc/key.pem
```

Finally, run gost:

```
gost -L=http+tls://:443 -logtostderr -v=2
```

If you don't see the error `open cert.pem: no such file or directory`, the Let's Encrypt certificate loaded successfully.

On the browser side, use SwitchyOmega to add this HTTPS proxy.
