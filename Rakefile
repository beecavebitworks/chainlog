require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test

Rake.load_rakefile 'lib/tasks/chainlog.rake'
Rake.load_rakefile 'lib/tasks/yard.rake'
