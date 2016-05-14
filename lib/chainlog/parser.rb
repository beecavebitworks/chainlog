require 'digest'

module ChainLog

  #
  # Used to parse and validate hash chains in log files generated by ChainLog::Formatter
  #
  class Parser

    def initialize
      @verbose=false
      @num=0
      @invalid=0
      @pid_to_last_line={}
    end

    ##########
    # Performs a simple parse of line and returns initialized ChainLog::Entry instance.
    # No hash chain validation is performed.
    #
    # @param line Raw line from log file
    # @return entry
    ##########
    def parse_entry(line)

      return nil if line.nil? || line.length <= 0
      meta,msg = line.split(' : ',2)
      msg = msg.chomp unless msg.nil?

      parts=meta.split(' ')

      fields=[]

      unless parts.length < 3
        fields_str=parts[2][1..-2]
        fields = fields_str.split(',')
      end

      Entry.new(parts[0], parts[1], fields, msg, line)
    end

    ##########
    # Validates the hash chain.
    # side-effect: All chain state is updated here. Should only be called once per line.
    #
    # @param entry ChainLog::Entry instance returned from parse_line
    #
    # @return nil if @computed_hash not yet set
    # @return true if hash in line matches computed_hash
    # @return false otherwise
    ##########
    def is_valid_hash(entry)

      return false if entry.nil?
      return false unless entry.parse_ok?

      last_line = _get_last_line(entry.pid)
      unless last_line.nil?
        computed_hash = ChainLog::Formatter.hash_str(last_line.chomp)
        entry.valid_chain = (computed_hash == entry.hash)

        if @verbose
          puts '"' + last_line + '"'
          puts computed_hash + " vs #{entry.hash}"
        end

      end

      # compute hash of this line for next call

      _set_last_line(entry.pid, entry.line)

      entry.valid_chain
    end

    def _get_last_line(pid)
      return nil unless @pid_to_last_line.has_key? pid
      @pid_to_last_line[pid]
    end

    def _set_last_line(pid, line)
      @pid_to_last_line[pid] = line
    end

    def _add_to_last_line(pid, line)
      @pid_to_last_line[pid] += line
    end

    ##########
    # Parses the line and validates chain
    # @param line A single line from logfile. This func will strip out newlines.
    # @return ChainLog::Entry instance.  Call entry.hash_chain_broken? for result.
    ##########
    def parse_and_validate_line(line)

      entry = parse_entry(line)
      return entry unless entry.parse_ok?

      valid_chain=is_valid_hash(entry)
      @invalid += 1 if valid_chain === false
      @num += 1

      entry
    end

    ##########
    # @return number of lines processed.
    ##########
    def num
      @num
    end

    ##########
    # return number of invalid lines encountered.
    ##########
    def invalid
      @invalid
    end

    ##########
    # Set verbose flag.  In verbose mode, each line is printed to stdout, followed by a computed hash.
    ##########
    def verbose=(val)
      @verbose=val
    end

    ##########
    # Process file and have block called for each parsed line.
    # @param file_path The file to read and process
    # @param block Called with line,entry parameters for each line
    ##########
    def parse_file(file_path, &block) # with block
      begin
        File.open(file_path) { |f|

          while true
            line = f.gets
            break if line.nil?
            next if @num == 0 && line[0] == '#'    # first line in log file, not seen by formatter

            entry = parse_and_validate_line(line)
            unless entry.parse_ok?
              # append to previous?
              throw "not implemented"
            else
              yield line, entry
            end
          end

        }
      rescue Exception => ex
        puts "Exception:#{ex.message}"
        puts ex.backtrace
      end
    end

    ##########
    # Processes and validates hash chain for each line
    # @param file_path String path of file or STDIN
    # @return [err_msg, num_lines]
    #   err_msg === false on success, string message otherwise
    #   num_lines is integer number of lines read before returning
    ##########
    def verify_file(file_path) # with block
      begin
        f = file_path
        f = File.open(file_path) if file_path.is_a? String


        prev_entry=nil

        while true
          line = f.gets
          break if line.nil?
          next if @num == 0 && line[0] == '#'    # first line in log file, not seen by formatter

          entry = parse_and_validate_line(line)

          if entry.nil?
            return "ERROR: unable to parse line #{@num}:\n#{line}", @num

          elsif entry.parse_ok?
            if entry.hash_chain_broken?
              err= "ERROR: hash chain broken at line #{@num}:\n#{line}"
              return err, @num
            end
            prev_entry = entry
          else
            # unrecognized format - could be continuation of multi-line

            if prev_entry
              _add_to_last_line(prev_entry.pid, line)
            else
              # file begins with unrecognized format?  Skip
            end
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

  end

  # Contains parsed components of a log entry line generated by ChainLog::Formatter.
  # Example format:
  #
  # I 2016-05-13T16:06:03.193710 [19892,,d84,7,3e40] : Started GET "/" for ::1 at 2016-05-13 16:06:03 -0500
  #
  class Entry
    attr_reader :severity, :ts, :msg, :line
    attr_accessor :valid_chain

    ########
    # Initialize object with parsed values.  valid_chain will be set to nil.  You must set valid_chain separately.
    # @param sev Single-character string representing log severity (I=Info, etc.)
    # @param ts String Datetime
    # @param fields String[] of meta-data inserted by Formatter
    # @param msg String message logged
    # @param line Raw line from log file
    ########
    def initialize(sev, ts, fields, msg, line)
      @severity=sev
      @ts=ts
      @fields=fields
      @msg=msg
      @line = line
      @valid_chain=nil
    end

    ########
    # @return array of meta-data field strings [pid,...,hash]
    ########
    def fields
      @fields
    end

    ########
    # Get hash chain suffix present in the logfile line
    ########
    def hash
      @fields.last
    end

    ########
    # Get process id string value
    # @return String Process id written by Formatter
    ########
    def pid
      @fields.first
    end

    ########
    # Check to see if hash chain is still intact with this line (Attribute valid_chain must have been set prior).
    # @return true Only if valid_chain has been set (not the default nil value) and is false.
    ########
    def hash_chain_broken?
      @valid_chain === false
    end

    ########
    # A basic sanity check
    # @return true If values are in place for severity,pid,hash
    ########
    def parse_ok?
      return false if @severity.nil? || @severity.length != 1
      return false if @fields.nil? || @fields.length < ChainLog::Formatter::NUM_FIELDS
      true
    end

    ########
    # Dump of key components used for debugging
    ########
    def to_s
      return "sev:#{@severity} ts:#{@ts} msg:'#{@msg}'" if fields.nil?
      "pid:#{pid} hash:#{hash} sev:#{@severity} ts:#{@ts}"
    end
  end

end
