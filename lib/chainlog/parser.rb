require 'digest'

module ChainLog

  class Parser

    def initialize
      @verbose=false
      _reset
    end

    #------------------------------------------
    # caller must ensure line does not contain newline at end (use chomp)
    #------------------------------------------
    def self.parse_entry(stripped_line)

      return nil if stripped_line.nil? || stripped_line.length <= 0
      meta,msg = stripped_line.split(' : ',2)

      parts=meta.split(' ')
      return nil if parts.length < 3
      fields_str=parts[2][1..-2]
      fields = fields_str.split(',')
      return nil if fields.length != ChainLog::Formatter::NUM_FIELDS

      return Entry.new(parts[0], parts[1], fields, msg)
    end

    #------------------------------------------
    # is_valid_hash
    # side-effect: updates @@pid_to_computed_hash_map
    # returns: nil if @computed_hash not yet set
    #         true if hash in line matches @computed_hash, false otherwise
    #------------------------------------------
    def is_valid_hash(stripped_line, entry=nil)

      entry = Parser.parse_entry(stripped_line) if entry.nil?
      return false if entry.nil?
      return false unless entry.parse_ok?

      if @pid_to_computed_hash_map.has_key?(entry.pid)
        entry.valid_chain = (@pid_to_computed_hash_map[entry.pid] == entry.hash)
      end

      # compute hash of this line for next call

      @pid_to_computed_hash_map[entry.pid] = ChainLog::Formatter.hash_str(stripped_line)
      if @verbose
        puts '"' + stripped_line + '"'
        puts @pid_to_computed_hash_map[entry.pid]
      end

      entry.valid_chain
    end

    #------------------------------------------
    # parse_and_validate_line
    # returns ChainLog::Entry instance
    #------------------------------------------
    def parse_and_validate_line(line)

      stripped_line=line.chomp
      entry = Parser.parse_entry(stripped_line)

      valid_chain=is_valid_hash(stripped_line, entry)
      @invalid += 1 if valid_chain === false
      @num += 1

      entry
    end

    def num
      @num
    end

    # return number of invalid lines
    def invalid
      @invalid
    end

    def verbose=(val)
      @verbose=val
    end

    #------------------------------------------
    #------------------------------------------
    def parse_file(file_path) # with block
      _reset
      begin
        File.open(file_path) { |f|

          while true
            line = f.gets
            break if line.nil?
            next if @num == 0 && line[0] == '#'    # first line in log file, not seen by formatter

            obj = parse_and_validate_line(line)
            yield line, obj
          end

        }
      rescue Exception => ex
        puts "Exception:#{ex.message}"
        puts ex.backtrace
      end
    end

    #------------------------------------------
    # returns [err_msg, num_lines]
    # where
    #   err_msg === false on success, string message otherwise
    #   num_lines is integer number of lines read before returning
    #------------------------------------------
    def verify_file(file_path) # with block
      _reset
      begin
        f = file_path
        f = File.open(file_path) if file_path.is_a? String


          while true
            line = f.gets
            break if line.nil?
            next if @num == 0 && line[0] == '#'    # first line in log file, not seen by formatter

            entry = parse_and_validate_line(line)
            if entry.hash_chain_broken?
              err= "ERROR: hash chain broken at line #{@num}:\n#{line}"
              return err, @num
            end
          end

        f.close

      rescue Exception => ex
        msg= "Exception:#{ex.message}"
        puts msg
        puts ex.backtrace
        return msg,@num
      end

      return false,@num
    end

    def _reset
      @num=0
      @invalid=0
      @pid_to_computed_hash_map={}
    end

  end

  class Entry
    attr_reader :severity, :ts, :msg
    attr_accessor :valid_chain

    def initialize(sev, ts, fields, msg)
      @severity=sev
      @ts=ts
      @fields=fields
      @msg=msg
      @valid_chain=nil
    end

    def fields
      @fields
    end

    def hash
      @fields.last
    end

    def pid
      @fields.first
    end

    def hash_chain_broken?
      @valid_chain === false
    end

    def parse_ok?
      return false if @severity.nil? || @severity.length != 1
      return false if @fields.nil? || @fields.length < ChainLog::Formatter::NUM_FIELDS
      true
    end

    def to_s
      return "sev:#{@severity} ts:#{@ts} msg:'#{@msg}'" if fields.nil?
      "pid:#{pid} hash:#{hash} sev:#{@severity} ts:#{@ts}"
    end
  end

end
