# Unix域套接字远程转发

名称: `runix`

状态： Stable

RUNIX处理器根据服务中的转发器配置，将数据转发给指定的目标Unix域套接字。

=== "命令行"
    ```bash
    gost -L runix://./app.sock/var/run/remote.sock
    ```
=== "配置文件"
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
          addr: /var/run/remote.sock
    ```

## 参数列表

无

!!! note "限制"
    RUNIX处理器只能与[runix监听器](/reference/listeners/runix/)一起使用，构建Unix域套接字远程转发服务。

