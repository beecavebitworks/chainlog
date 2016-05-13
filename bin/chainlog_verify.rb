#!/usr/bin/env ruby
require 'chainlog'

parser = ChainLog::Parser.new

if ARGV.length < 1
  puts "Usage: <script> [-v] filename"
  exit 1
end

i=0
if ARGV[i] == '-v'
  parser.verbose=true
  i+=1
end

if ARGV.length < i+1
  puts "reading from stdin"
  file=STDIN
else
  file=ARGV[i]
end

err,num_lines = parser.verify_file(file)
if err
  puts err
else
  puts "Verified hash chain for #{num_lines} lines"
end
