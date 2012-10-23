# Wabo
<b>Wa</b>tch <b>B</b>uild <b>O</b>pen. **Currently in _beta_ status**. After testing is over I will package it as a gem.

Watches the current directory (recursively) for changes and performs an action. Only on Mac OS X and with Chrome.

You may specify one of a number of options which will be executed in the following order:

1. Start a static file web server.
1. Run the command. Waits for the command to complete before continuing.
1. Kill and rerun the daemon. Use this for commands that do not finish (web servers).
1. Wait a number of miliseconds.
1. Open or refresh the URL.

## Installation

### Manual Installation
Clone this repo.  Run `gem install colorize rb-fsevent trollop`. Optionally symlink wabo into your path.

### Bundler
Clone this repo.  Run `bundle`. Optionally symlink wabo into your path.

## Examples
* Read help/usage: `wabo -h`
* Watch and open a local php app: `wabo -u http://someapp.local/foo.php`
* Watch, build and open a markdown file, serving it using the builtin web server: `wabo -s 4040 -c maruku page.md -u http://localhost:4040/page.html`
* Watch, rebuild/restart a Go web server, wait 500ms for the restart, open: `wabo -a 'go build main.go' -w 500 -u http://localhost:8080/`

## Usage
	--directory, -d <s>:   Directory to watch, defaults to current working directory
	--command, -c <s>:   Shell command to execute, use && for multiple commands
	--daemon, -a <s>:   Service to run and restart
	--wait, -w <i>:   Nanoseconds to wait before refreshing the URL. Use this to wait for your daemon to restart
	--url, -u <s>:   URL to open/refresh
	--serve, -s <i>:   Starts a web server on the given port. Example: `wabo --serve 4000 --url http://localhost:4000/`
	--verbose, --no-verbose, -v:   Output debug info (default: true)
	--help, -h:   Show this message

## Issues

If an additional new tab is opening instead of the existing tab refreshing, ensure your URL has the trailing /.  Chrome adds this automatically to the end of domain names but Wabo does not currently.
