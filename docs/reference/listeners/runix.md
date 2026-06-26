# Unix域套接字远程转发

名称: `runix`

状态： Stable

RUNIX监听器根据服务配置，通过转发链在远程主机上监听Unix域套接字(Unix Domain Socket)端口，并将其接受的连接转发回本地。

## 不使用转发链

=== "命令行"
    ```
    gost -L=runix://./app.sock
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
          addr: /var/run/app.sock
    ```

## 使用转发链

=== "命令行"
    ```
    gost -L=runix://./app.sock/var/run/remote.sock -F relay://192.168.1.2:8421
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
        chain: chain-0
      forwarder:
        nodes:
        - name: target-0
          addr: /var/run/remote.sock
    chains:
    - name: chain-0
      hops:
      - name: hop-0
        nodes:
        - name: node-0
          addr: 192.168.1.2:8421
          connector:
            type: relay
          dialer:
            type: tcp
    ```

## 使用场景

RUNIX监听器适用于通过GOST转发链将远端Unix域套接字服务暴露到本地。例如：

- 将远端Docker守护进程(`/var/run/docker.sock`)通过转发链暴露到本地
- 将远端MySQL数据库的Unix域套接字转发到本地
- 将远端HTTP服务的Unix域套接字转发到本地

## 参数列表

无

!!! note "限制"
    RUNIX监听器只能与[RUNIX处理器](/reference/handlers/runix/)一起使用，构建Unix域套接字远程转发服务。

!!! note "注意"
    Unix域套接字路径是文件系统中的路径。当使用转发链时，目标地址必须是一个Unix域套接字路径（例如 `/var/run/app.sock`）。
    转发链的最后一跳必须支持Unix域套接字绑定（例如使用relay连接器）。
