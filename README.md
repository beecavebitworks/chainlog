# chainlog
This gem provides Rails logger with two key features:
###hash chain
  Each line contains part of a SHA-256 digest of the previous line.
###json
  log a hash dictionary and it will be written as json, which is automatically supported by many log management utilities.  Use this to tag your logs with metadata that can be correlated across containers and tiers.
  
A parser is provided to verify entire log files or snippets.
Each process gets it's own copy of the logger, so a log file will have chains for each process intermingled.  The Parser handles this case.

# Adding the Formatter to your environment

Its as easy as adding two lines to your *config/environment.rb*:

```ruby
require 'chainlog'
Rails.application.config.log_formatter = ChainLog::Formatter.new
```

#Example Log Entries
<pre>
I 2016-05-13T16:06:02.702771 [19893,,16c,2,6435] :   Parameters: {"flash"=>"false"}
I 2016-05-13T16:06:02.705831 [19893,,16c,3,58fb] : Completed 200 OK in 3ms (Views: 0.4ms | ActiveRecord: 0.0ms)
D 2016-05-13T16:06:03.193366 [19892,,d84,5,f82f] :
D 2016-05-13T16:06:03.193544 [19892,,d84,6,9b54] :
I 2016-05-13T16:06:03.193710 [19892,,d84,7,3e40] : Started GET "/" for ::1 at 2016-05-13 16:06:03 -0500
</pre>
The first character is the log severity (I=Info, D=Debug, W=Warn,etc.)
The bracketed section after the timestamp contains the following fields:

| Field Name | Description |
|-------------|
|pid         | The process id |
|progname    | Name of the program... often empty |
|thread_id   | Thread identifier. Last 3 hex chars of Thread.current.object_id |
|line_counter| Single digit rolling counter for the pid |
|hash_chain  | Last 4 chars of SHA-256 of previous log entry for same pid |

# Verifying with a script

`./bin/chainlog_verify.rb path/to/some.log`

or

`tail -50 path/to/some.log | ./bin/chainlog_verify.rb`

# Verifying programmatically

```ruby
require 'chainlog'
parser = ChainLog::Parser.new
err,num_lines = parser.verify_file(file_path)
alert_user if err
```
