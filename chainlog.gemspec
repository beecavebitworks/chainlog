Gem::Specification.new do |s|
  s.name        = 'chainlog'
  s.version     = '0.7.8'
  s.date        = '2016-05-13'
  s.summary     = "A Rails Logger formatter/parser that includes hash chaining and JSON params"
  s.description = "Enable in config/environments/production.rb with require 'chainlog'; Rails.logger=Logger.new; Rails.logger.formatter = ChainLog.Formatter.new "
  s.authors     = ["Alex Malone"]
  s.email       = 'originalsix@bluesand.org'
  s.files       = ["lib/chainlog.rb", "lib/chainlog/formatter.rb", "lib/chainlog/parser.rb" ]
  s.homepage    = 'https://github.com/beecavebitworks/chainlog'
  s.license     = 'Apache 2.0'
end
