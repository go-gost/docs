# 主机IP映射

## 映射器

映射器是一个主机名到IP地址的映射表，通过映射器可在DNS请求之前对域名解析进行人为干预。当需要进行域名解析时，GOST会先通过映射器查找是否有对应的IP定义，如果有则直接使用此IP地址。如果映射器中没有定义，再使用DNS服务查询。

=== "命令行"
	```
	gost -L http://:8080?hosts=example.org:127.0.0.1,example.org:::1,example.com:2001:db8::1
	```

	通过`hosts`参数来指定映射表。映射项为以`:`分割的host:ip对，ip可以是ipv4或ipv6格式。

=== "配置文件"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
      hosts: hosts-0
	  handler:
		type: http
	  listener:
		type: tcp
	hosts:
	- name: hosts-0
	  mappings:
	  - ip: 127.0.0.1
		hostname: example.org
	  - ip: ::1
		hostname: example.org
	  - ip: 2001:db8::1
		hostname: example.com
	```

	服务使用`hosts`属性通过引用映射器名称(name)来使用指定的映射器。

## DNS代理服务

映射器在DNS代理服务中会直接应用到DNS查询。

```
gost -L dns://:10053?dns=1.1.1.1&hosts=example.org:127.0.0.1,example.org:::1,example.com:2001:db8::1
```

此时解析example.org会匹配到映射器而不会使用1.1.1.1查询。

!!! example "DNS查询example.org(ipv4)"
	```
	dig -p 10053 example.org
	```

	```
	;; QUESTION SECTION:
    ;example.org.				IN	A

    ;; ANSWER SECTION:
    example.org.		3600	IN	A	127.0.0.1
	```

!!! example "DNS查询example.org(ipv6)"
	```
	dig -p 10053 AAAA example.org
	```

	```
	;; QUESTION SECTION:
    ;example.org.				IN	AAAA

    ;; ANSWER SECTION:
    example.org.		3600	IN	AAAA	::1
	```

解析example.com时，由于ipv4在映射器中无对应项，因此会使用1.1.1.1进行解析。

!!! example "DNS查询example.com(ipv4)"
	```
	dig -p 10053 example.com
	```

	```
	;; QUESTION SECTION:
    ;example.com.				IN	A

    ;; ANSWER SECTION:
    example.com.		10610	IN	A	93.184.216.34
	```

!!! example "DNS查询example.com(ipv6)"
	```
	dig -p 10053 AAAA example.com
	```

	```
	;; QUESTION SECTION:
    ;example.com.				IN	AAAA

    ;; ANSWER SECTION:
    example.com.		3600	IN	AAAA	2001:db8::1
	```