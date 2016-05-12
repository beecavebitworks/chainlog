require 'digest'

module ChainLog

  class Parser

    def initialize
      @num=0
      @invalid=0
      @computed_hash=nil
    end

    #------------------------------------------
    # caller must ensure line does not contain newline at end (use strip or chomp)
    # assumes that line ends with ";xxxxxx"
    # where xxxxxx is a 6-character suffix of the SHA256
    #------------------------------------------
    def self.extract_hash_from_line(stripped_line)
      hash = stripped_line[-7..-1]
      return nil if hash.length < 7 || hash[0] != ';'
      hash[1..-1]
    end

    #------------------------------------------
    # is_valid_hash
    # side-effect: updates @computed_hash
    # returns: nil if @computed_hash not yet set
    #         true if hash in line matches @computed_hash, false otherwise
    #------------------------------------------
    def is_valid_hash(stripped_line)
      valid_chain=nil
      provided_hash = Parser.extract_hash_from_line stripped_line
      if @computed_hash
        valid_chain= (@computed_hash == provided_hash)
      end

      # compute hash of this line for next call

      @computed_hash = ChainLog::Formatter.hash_str(stripped_line)

      valid_chain
    end

    #------------------------------------------
    # parse_line
    #------------------------------------------
    def parse_line(line)

      stripped_line=line.chomp
      valid_chain=is_valid_hash(stripped_line)
      @invalid += 1 if valid_chain === false

      @num += 1

      # TODO:

      a=line.split(' ',3)
      sev=a[0]
      ts=a[1]
      msg=a[2]
      provided_hash = Parser.extract_hash_from_line stripped_line

      {severity:sev, ts:ts, message:msg, hash:provided_hash, valid_chain: valid_chain}
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
            next if @num == 0 && line[0] == '#'    # first line in log file, not seen by formatter

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
