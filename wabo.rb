#!/usr/bin/env ruby

# output immediately instead of buffering
STDOUT.sync = true

require 'colorize'
require 'rb-fsevent'
require 'trollop'

$opts = Trollop::options do
  banner <<-eod
Watches the current directory (recursively) for changes and performs an action. Only on Mac OS X and with Chrome.

You must specify at least one action, they will be executed in order:
	0. Start a static file web server.
	1. Run the command. Waits for the command to complete before continuing.
	2. Kill and rerun the daemon. Use this for commands that do not finish.
	3. Open or refresh the URL.

If an additional new tab is opening instead of the existing tab refreshing, ensure your URL has the trailing /

Examples:
	* Watch a local php app:
		wabo -u http://someapp.local/foo.php
	* Watch and build a Jeckyl blog:
		wabo -c jeckyl -u http://localhost:4000/
	* Watch and restart a Go web server:
		wabo -a 'go build main.go' -u http://localhost:8080/
  eod

  opt :directory, "Directory to watch, defaults to current working directory", :type=>:string, :default=>Dir.pwd
  opt :command, "Shell command to execute, use && for multiple commands", :type=>:string
  opt :daemon, "Service to run and restart", :type=>:string
	opt :wait, "Nanoseconds to wait before refreshing the URL. Use this to wait for your daemon to restart", :type=>:int
  opt :url, "URL to open/refresh", :type=>:string

	opt :serve, "Starts a web server on the given port. Example: dirwatch --serve 4000 --url http://localhost:4000/", :type=>:int
  opt :verbose, "Output debug info", :default=>true
end

Trollop::die "You must specify at least one action" unless $opts[:command] or $opts[:daemon] or $opts[:url] or $opts[:serve]

def log(m)
	puts m if $opts[:verbose]
end

$chrome_applescript = <<-eod
  tell application "Google Chrome"
    activate
    set theUrl to "#{$opts[:url]}"
    
    if (count every window) = 0 then
      make new window
    end if
    
    set found to false
    set theTabIndex to -1
    repeat with theWindow in every window
      set theTabIndex to 0
      repeat with theTab in every tab of theWindow
        set theTabIndex to theTabIndex + 1
        if theTab's URL = theUrl then
          set found to true
          exit
        end if
      end repeat
      
      if found then
        exit repeat
      end if
    end repeat
    
    if found then
      tell theTab to reload
      set theWindow's active tab index to theTabIndex
      set index of theWindow to 1
    else
      tell window 1 to make new tab with properties {URL:theUrl}
    end if
  end tell
eod


if $opts[:serve]
	log "starting server".green

	$server_pid = fork do
		require 'webrick'

		server = WEBrick::HTTPServer.new(:Port=>$opts[:serve],:DocumentRoot=>$opts[:directory])
		trap("INT"){ server.shutdown }

		server.start
	end
end

$daemon_pid = nil
def restart_daemon
	if $daemon_pid
		log "killing daemon: ".yellow + $daemon_pid.to_s
		Process.kill("INT", -Process.getpgid($daemon_pid)) 
	end

	trap("INT") do
		log "killing daemon: ".yellow + $daemon_pid.to_s
		Process.kill("INT", -Process.getpgid($daemon_pid)) 
		exit
	end

	$daemon_pid = fork do
		log "starting daemon: ".green + $opts[:daemon]
		exec $opts[:daemon], {:pgroup=>true}
	end
end

def action
	if $opts[:command]
		log "running command: ".green + $opts[:command]
		IO.popen($opts[:command]) do |f| 
			loop do
				b = f.read 1
				break unless b
				print b
			end
		end
	end
	
	if $opts[:daemon]
		restart_daemon
	end

  if $opts[:url]
		if $opts[:wait]
			s = $opts[:wait].to_f / 1000
			log "waiting #{s}s".green
			sleep s
		end

		log "opening url: ".green + $opts[:url]
    io = IO.popen('osascript', 'r+')
    io.write $chrome_applescript
    io.close_write
    io.readlines
  end
end

# action on startup
action

fsevent = FSEvent.new
fsevent.watch $opts[:directory] do |directories|
  log "Detected change inside: #{directories.inspect}"
	action
end
fsevent.run
