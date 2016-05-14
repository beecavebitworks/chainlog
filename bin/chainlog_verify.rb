#!/usr/bin/env ruby
require 'chainlog'

parser = ChainLog::Parser.new

# copy args without -v and set verbose flag
args=[]
ARGV.each {|arg|
  args<<arg unless arg=='-v'
  parser.verbose=true if arg=='-v'
}

# are we reading from file or stdin?

if args.length < 1
  puts "reading from stdin"
  file=STDIN
else
  file=ARGV.last
end

# run

err,num_lines = parser.parse_file(file)
if err
  puts err
else
  puts "Verified hash chain for #{num_lines} lines"
end
