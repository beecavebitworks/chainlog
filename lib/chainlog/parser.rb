require 'digest'
require 'active_support/logger'

module ChainLog

  class Parser

    def initialize
      @num=0
      @skipped=0
      @invalid=0
      @prev_line=nil
      @prev_hash=nil
    end

    #------------------------------------------
    # assumes that line ends with ";xxxxxx"
    # where xxxxxx is a 6-character suffix of the SHA256
    #------------------------------------------
    def self.extract_hash_from_line(line)
      hash = line.strip[-7..-1]
      return nil if hash.length < 7 || hash[0] != ';'
      hash[1..-1]
    end

    #------------------------------------------
    # parse_line
    #------------------------------------------
    def parse_line(line)
      @num += 1
      hash = Parser.extract_hash_from_line line
      if @prev_line
        computed_prev_hash=ChainLog::Logger.hash_str(@prev_line.strip)
        valid_chain= computed_prev_hash == hash
        #puts "#{hash} vs h(prev) #{computed_prev_hash}"
        @invalid += 1 unless valid_chain
      else
        valid_chain=true
      end
      @prev_line = line
      @prev_hash = hash


      a=line.split(' ',3)
      sev=a[0]
      ts=a[1]
      msg=a[2]

      @num += 1

      {severity:sev, ts:ts, message:msg, hash:hash, valid_chain: valid_chain}

    end

    def num
      @num
    end

    def invalid
      @invalid
    end

    def parse_file(file_path) # with block
      begin
        File.open(file_path) { |f|

          while true
            line = f.gets
            break if line.nil?
            next if line[0] == '#'    # first line in log file

            obj = parse_line(line)
            yield line, obj
          end

        }
      rescue Exception => ex
        puts "Exception:#{ex.message}"
        puts ex.backtrace
      end
    end
  end

end
