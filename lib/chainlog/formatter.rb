module ChainLog

  # formatter for log messages that includes hash chaining

  class Formatter

    Format = "%s %s %d %s : %s"

    attr_accessor :datetime_format

    def initialize
      @datetime_format = nil
      @dup_mode = true

      @last_hash = Formatter.hash_str('') # 52b855
      @last_message = nil
      @last_output = nil
      @num=0
      @lock = Mutex.new
    end

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

        s= Format % [severity[0..0], format_datetime(time), $$, progname, msg2str(msg)]

        # append hash of last line

        s << " ;#{@last_hash}"

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

    def self.hash_str(line)
      Digest::SHA256.hexdigest(line)[-6..-1]
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