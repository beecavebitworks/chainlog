
module ChainLog

  # formatter for log messages that includes hash chaining.  Based on Logger.Formatter
  # Enable in config/environment.rb with:
  #
  # Rails.application.config.log_formatter = ChainLog::Formatter.new
  #
  class Formatter

    # Names of meta-data fields

    FIELD_NAMES=%w(pid,program,thread,line,chain)

    # Number of meta-data fields
    NUM_FIELDS=5

    # Number of hex chars of SHA digest to keep
    HASH_LEN=4

    attr_accessor :datetime_format

    def initialize
      @datetime_format = nil
      @lock = Mutex.new

      @dup_mode = true
      @last_hash = Formatter.hash_str('') # 52b855
      @last_message = nil
      @last_output = nil
      @num=0
    end

    #########
    # return HASH_LEN hex chars of SHA256(line)
    # @param line Formatted log entry without trailing newlines
    #########
    def self.hash_str(line)
      Digest::SHA256.hexdigest(line)[-HASH_LEN..-1]
    end

    #########
    # Called by Logger to format line
    #########
    def call(severity, time, progname, msg)
      @lock.synchronize {
        @num += 1

        if @dup_mode

          # by default, dup_mode is on, so check first several messages to see if it doesn't happen

          if @num < 10 && !@last_message.nil?

            # turn off dup mode if every other message is not the same
            @dup_mode = false  if (@num % 2 == 0) && @last_message != msg
          end
          return @last_output if @last_message == msg && (@num % 2 == 0)
        end

        tid = Thread.current.object_id.to_s(16)[-3..-1]
        lineno = @num
        lineno = (@num + 1) / 2 if @dup_mode    # without this, would read 1, 3, 5, 7, ...
        lineno = lineno.to_s[-1..-1]

        pname=progname
        # make sure program name, if present, does not have spaces. For parsing reasons
        pname=pname.gsub(' ','_') unless pname.nil?

        s= "%s %s [%d,%s,%s,%s,%s] : %s" % [
             severity[0..0], format_datetime(time),
             $$, pname, tid, lineno , @last_hash,
             msg2str(msg)]

        # create hash of this line for use next time

        @last_message = msg
        @last_hash = Formatter.hash_str(s)

        s << "\n"

        @last_output = s
      }
    end

    private

    def format_datetime(time)
      if @datetime_format.nil?
        time.strftime("%Y-%m-%dT%H:%M:%S.") << "%06d" % time.usec
      else
        time.strftime(@datetime_format)
      end
    end

    def msg2str(msg)
      case msg
        when ::String
          msg
        when ::Exception
          "#{ msg.message } (#{ msg.class })\n" <<
            (msg.backtrace || []).join("\n")
        else
          msg.to_json
      end
    end
  end

end