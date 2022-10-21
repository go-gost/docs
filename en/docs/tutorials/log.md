# Log

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

## Level

The supported levels are:

* `fatal` - The program will exit when this level of logging is output.
* `error` - General errors, the program runs normally.
* `warn` - warnings that you should be noticed.
* `info` - general infos.
* `debug` - Output more information than `info` level, used to locate problems during development or use.
* `trace` - More information than `debug` level output, useful for development debugging.

The default level is `info`.

!!! tip "CLI"
    The `debug` level can be set through the `-D` parameter on the command line, or the corresponding level can be set through the environment variable `GOST_LOGGER_LEVEL`.

## Format

The log supports `json` and `text` formats, the default is `json` format.

## Output

The supported output methods are:

* `none` - Discard the log without outputting any information.
* `stderr` - standard error stream.
* `stdout` - Standard output stream.
* `/path/to/file` - The specified file path.

Defaults to output to the standard error stream (`stderr`).

## Rotation

Logs can be split, backed up and compressed by configuring the `rotation` option. Valid when `output` is a file.

`maxSize` (int, default=100)
:    The maximum size in megabytes of the log file before it gets rotated. It defaults to 100 megabytes.

`maxAge` (int)
:    The maximum number of days to retain old log files based on the timestamp encoded in their filename. Note that a day is defined as 24 hours and may not exactly correspond to calendar days due to daylight savings, leap seconds, etc. The default is not to remove old log files based on age.

`maxBackups` (int)
:    the maximum number of old log files to retain. The default is to retain all old log files (though `maxAge` may still cause them to get deleted.)

`localTime` (bool, default=false)
:    Determines if the time used for formatting the timestamps in backup files is the computer's local time. The default is to use UTC time.

`compress` (bool, default=false)
:    Determines if the rotated log files should be compressed using gzip. The default is not to perform compression.

