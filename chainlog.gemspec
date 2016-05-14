Gem::Specification.new do |s|
  s.name        = 'chainlog'
  s.version     = '0.9.1'
  s.date        = '2016-05-14'
  s.summary     = "A Rails Logger formatter/parser that includes hash chain and JSON serialization"
  s.description = <<-EOS
This gem provides Rails logger with two key features: hash chain and JSON encoding of objects.  Each line contains a number of fields enclosed in brackets.  The first being the process id, and the last being the last 4-chars of the SHA-256 of the previous line.  When a server has been compromised, the intruders will often try to alter the log files to cover their tracks.  With this meta-data embedded, tampering of the log file can be detected (using script provided or programmatically).  The default Rails logger will serialize hashes and objects in ruby inspect format.  This formatter will instead encode them in JSON.  Some log management tools can automatically extract specified fields from JSON for indexing.
EOS
  s.authors     = ["Alex Malone"]
  s.email       = 'originalsix@bluesand.org'
  s.files       = ["lib/chainlog.rb", "lib/chainlog/formatter.rb", "lib/chainlog/parser.rb" ]
  s.executables << 'chainlog_verify.rb'
  s.homepage    = 'https://github.com/beecavebitworks/chainlog'
  s.license     = 'Apache 2.0'
end
