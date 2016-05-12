require 'minitest/autorun'
require 'chainlog'
require 'json'

class LoggerTest < Minitest::Test

  TEMP_LOG='./test/ttt123.log'

  def clean_temp_log
    File.delete TEMP_LOG if File.exist? TEMP_LOG
  end

  def test_log
    clean_temp_log
    logger = ChainLog::Logger.new(TEMP_LOG)
    logger.warn "hola"

    obj={a:1, b:'32233'}
    j=obj.to_json
    logger.error "something gone wrong #{j}"

    logger.info obj

    logger = nil
    parser = ChainLog::Parser.new

    File.open(TEMP_LOG, 'r') {|f|
      lines=f.readlines
      uno = parser.parse_line(lines[1])
      assert_equal 'W', uno[:severity]
      assert_equal ChainLog::Logger.hash_str(''), uno[:hash]
    }

    parser = ChainLog::Parser.new
    parser.parse_file(TEMP_LOG) { |line, item|
      assert item[:valid_chain], "Invalid chain on line #{line}"
    }
  end


end
