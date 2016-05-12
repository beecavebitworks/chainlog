module ChainLog


  # formatter for log messages that includes hash chaining

  class Formatter
    Format = "%s %s %d %s: %s"

    attr_accessor :datetime_format

    def initialize
      @datetime_format = nil
      @last_hash = Formatter.hash_str('')
    end

    def call(severity, time, progname, msg)
      s= Format % [severity[0..0], format_datetime(time), $$, progname,
                msg2str(msg)]

      # append hash of last line

      s << " ;#{@last_hash}"

      # create hash of this line for use next time

      @last_hash = Formatter.hash_str(s)

      s << "\n"
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