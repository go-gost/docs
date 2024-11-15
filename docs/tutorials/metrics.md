---
comments: true
---

# 监控指标

GOST内部通过[Prometheus](https://prometheus.io/)的指标(Metrics)来提供监控数据。

## 开启监控

通过`metrics`参数来开启监控指标记录，默认不开启。

=== "命令行"

	```bash
	gost -L :8080 -metrics :9000
	```

	开启认证并设置选项

	```bash
	gost -L :8080 -metrics "user:pass@:9000?path=/metrics"
	```

=== "配置文件"

    ```yaml
	services:
	- name: service-0
	  addr: ":8080"
	  handler:
		type: auto
	  listener:
		type: tcp

	metrics:
	  addr: :9000
	  path: /metrics
	  auth:
	    username: user
		password: pass
	  auther: auther-0
	```

	`metrics.addr` (string)
	:    监控指标HTTP API服务地址

	`metrics.path` (string, default=/metrics)
	:    API路径

### 身份认证

身份认证采用[HTTP Basic Auth](https://en.wikipedia.org/wiki/Basic_access_authentication)方式。

配置文件中通过`auth`或`auther`选项可以设置身份认证信息，如果设置了`auther`选项，`auth`选项则会被忽略。

=== "命令行"

    ```bash
    gost -L :8080 -metrics "user:pass@:9000"
    ```

=== "配置文件"

    ```yaml
    metrics:
      addr: :9000
      auth:
        username: user
        password: pass
      auther: auther-0
    ```

开启之后可以通过`http://localhost:9000/metrics`地址查看到指标数据。

!!! example "指标示例"
    ```
    gost_chain_errors_total{chain="chain-0",host="host-0"} 1

	gost_service_handler_errors_total{host="host-0",service="service-0"} 1

	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="0.005"} 0
	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="0.01"} 0
	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="0.025"} 0
	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="0.05"} 0
	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="0.1"} 0
	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="0.25"} 1
	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="0.5"} 1
	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="1"} 1
	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="2.5"} 1
	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="5"} 1
	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="10"} 1
	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="15"} 1
	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="30"} 2
	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="60"} 2
	gost_service_request_duration_seconds_bucket{host="host-0",service="service-0",le="+Inf"} 2
	gost_service_request_duration_seconds_sum{host="host-0",service="service-0"} 15.172895206
	gost_service_request_duration_seconds_count{host="host-0",service="service-0"} 2

	gost_service_requests_in_flight{host="host-0",service="service-0"} 0

	gost_service_requests_total{host="host-0",service="service-0"} 2

	gost_service_transfer_input_bytes_total{host="host-0",service="service-0"} 1018

	gost_service_transfer_output_bytes_total{host="host-0",service="service-0"} 7327

	gost_services{host="host-0"} 1
	```

## 指标说明

`gost_services` (type=gauge)
:    运行的服务数量

`gost_service_requests_total` (type=counter)
:    服务处理的请求总数

`gost_service_transfer_input_bytes_total` (type=counter)
:    服务接收到的数据字节数

`gost_service_transfer_output_bytes_total` (type=counter)
:    服务发送出的数据字节数

`gost_service_requests_in_flight` (type=gauge)
:    服务当前正在处理中的请求数

`gost_service_request_duration_seconds_*` (type=histogram)
:    服务请求处理的时长分布

`gost_service_handler_errors_total` (type=counter)
:    服务处理请求失败数

`gost_chain_errors_total` (type=counter)
:    转发链本身建立连接失败数

## Prometheus

Prometheus配置文件`prometheus.yaml`需要在`scrape_configs`中增加一个Job。

```yaml hl_lines="5 6 7 8"
global:
  scrape_interval: 15s 
# A list of scrape configurations.
scrape_configs:
  - job_name: 'gost'
    scrape_interval: 5s
    static_configs:
      - targets: ['127.0.0.1:9000']
```

## Grafana Dashboard

你可以使用以下的Dashboard来呈现监控指标数据

[https://grafana.com/grafana/dashboards/16037](https://grafana.com/grafana/dashboards/16037)

![GOST Dashboard](../images/dashboard.png)