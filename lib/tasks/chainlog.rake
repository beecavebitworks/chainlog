namespace :chainlog do

  require 'chainlog'

  task :verify, [:file] do |t, args|
    parser = ChainLog::Parser.new
    filename=args[:file]
    filename=STDIN if filename.nil? || filename == '-'
    err,num_lines = parser.verify_file(filename)
    if err
      puts err
    else
      puts "Verified hash chain for #{num_lines} lines"
    end
  end

end