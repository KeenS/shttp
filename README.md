# An http server written in shell
## Usage

	$ cd documentroot
	$ /path/to/shttp.sh

The default port is 8080. To change listen port,

	$ PORT=4000 /path/to/shttp.sh

.

(Though experimentally) log format can be configured.
The default is equivalent to

    $ LOG_FORMAT='$TIMESTAMP $METHOD $REQUEST_PATH $USER_AGENT' /path/to/shttp.sha

. Be carefull for `$` not to be evaluated as shell variable.

## Notice
This is intended to be used locally
