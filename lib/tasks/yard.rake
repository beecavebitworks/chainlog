# uncomment require to enable yard:doc rake task
#require 'yard'

if defined? YARD
  namespace :yard do
    YARD::Rake::YardocTask.new(:doc) do |t|
    end
  end

  task :yard => ['yard:doc']
end
