require 'active_support/logger'

module ChainLog

  class Logger < ActiveSupport::Logger
    SEVERITY_NAME = %w( DEBUG INFO WARN ERROR FATAL UNKNOWN )
    SEVERITY_ABBREV = %w( D I W E F U )

    def self.hash_str(line)
      Digest::SHA256.hexdigest(line)[-6..-1]
    end

    def custom_line(severity, msg)
      # Customized Log Format!

      @last_message = '' if @last_message.nil?

      #chain_hash = Digest::SHA256.hexdigest(@last_message)[-6..-1]
      #puts "HASH #{chain_hash} for '#{@last_message}'"

      sev=SEVERITY_ABBREV[severity]
      ts=Time.now.strftime("%Y-%m-%d %H:%M:%S")

      "#{sev} #{ts} #{msg} ;#{Logger::hash_str(@last_message)}"

    end

    def jso(item)
      if item
        return item.to_json unless item.is_a? String
      end
      item
    end

    def add(severity, message = nil, progname = nil, &block)
      return if @level > severity

      message = (jso(message) || block && jso(block) || jso(progname))
      return if message.length == 0

      message = custom_line(severity, message) # <== CUSTOMIZED

      # If a newline is necessary then create a new message ending with a newline.
      # Ensures that the original message is not mutated.
      #message = "#{message}\n" unless message[-1] == ?\n

      @last_message = message
      #auto_flush
#      puts message

#      message
      @logdev.write(message + "\n")
#        format_message(message) )#format_severity(severity), Time.now, progname, message))

    end

  end
end

