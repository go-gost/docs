# 日志

```yaml
log:
  level: info
  format: json
  output: stderr
  rotation:
    maxSize: 100
	maxAge: 10
	maxBackups: 3
	localTime: false
	compress: false
```

## 级别

支持的级别有:

* `fatal` - 致命错误，当输出此级别的日志后程序将退出。
* `error` - 一般性错误，程序正常运行。
* `warn` - 需要注意的警告信息。
* `info` - 一般信息。
* `debug` - 比`info`级别输出更多信息，用于开发或使用过程中定位问题。
* `trace` - 比`debug`级别输出更多信息，用于开发调试。

默认级别为`info`。

!!! tip "命令行"
    命令行下可以通过`-D`参数设置`debug`级别，或者通过环境变量`GOST_LOGGER_LEVEL`来设置相应的级别。

## 格式

支持`json`和`text`两种格式，默认为`json`格式。

## 输出

支持的输出方式有：

* `none` - 丢弃日志，不输出任何信息。
* `stderr` - 标准错误流。
* `stdout` - 标准输出流。
* `/path/to/file` - 指定的文件路径。

默认输出到标准错误流(`stderr`)。

## Rotation

通过配置`rotation`选项可以对日志进行切分，备份和压缩。当`output`为文件时有效。

`maxSize` (int, default=100)
:    文件存储大小，单位为MB。

`maxAge` (int)
:    备份日志文件保存天数，默认不根据时间清理旧文件。

`maxBackups` (int)
:    备份日志文件数量，默认保存所有文件。

`localTime` (bool, default=false)
:    备份文件名是否使用本地时间格式。默认使用UTC时间。

`compress` (bool, default=false)
:    备份文件是否(使用gzip)压缩。

