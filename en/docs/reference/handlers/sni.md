# SNI

Name: `sni`

Status： GA

=== "CLI"
    ```
	gost -L sni://:8080
	```
=== "File (YAML)"
    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: sni 
	  listener:
		type: tcp
	```

## 参数列表

无
