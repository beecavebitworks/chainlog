require 'minitest/autorun'
require 'chainlog'
require 'active_support'
require 'json'

class FormatterTest < Minitest::Test

  TEMP_LOG='./test/fff123.log'

  def clean_temp_log
    File.delete TEMP_LOG if File.exist? TEMP_LOG
  end

  def test_log
    clean_temp_log
    logger = Logger.new(TEMP_LOG)
    logger.formatter = ChainLog::Formatter.new
    logger.warn "hola"

    obj={a:1, b:'32233'}
    j=obj.to_json
    logger.error "something gone wrong #{j}"

    logger.info obj

    logger = nil
    parser = ChainLog::Parser.new

    # now read back file and validate that the hash chains match

    File.open(TEMP_LOG, 'r') {|f|
      lines=f.readlines
      uno = parser.parse_line(lines[1])
      assert_equal 'W', uno[:severity]
      assert_equal ChainLog::Formatter.hash_str(''), uno[:hash]
    }

    parser = ChainLog::Parser.new
    parser.parse_file(TEMP_LOG) { |line, item|
      assert !(item[:valid_chain] === false), "Invalid chain on line #{line}"
    }

    parser = ChainLog::Parser.new
    err,num_lines = parser.verify_file(TEMP_LOG)
    assert err===false, err
    assert_equal 4,num_lines

  end

  def test_validate
    str = <<-EOS
W 2016-05-12T09:39:23.137259 5490 : hola ;52b855
E 2016-05-12T09:39:23.137327 5490 : something gone wrong {"a":1,"b":"32233"} ;6e2ef1
I 2016-05-12T09:39:23.137348 5490 : {"a":1,"b":"32233"} ;412205
EOS

    parser = ChainLog::Parser.new
    str.split("\n").each { |line|
      val = parser.is_valid_hash(line.chomp)
      assert !(val === false), "Invalid chain on line #{line}"
    }
  end

  def test_dup_log

    # emulates rails stdout_logger in development.  The formatter is shared between two loggers

    clean_temp_log
    logger = Logger.new(TEMP_LOG)
    logger.formatter = ChainLog::Formatter.new

    stdout_logger = Logger.new(STDOUT)
    stdout_logger.formatter = logger.formatter

    ["", "some message 1", "another message 2", "", "third times a charm 3"].each {|msg|
      logger.info msg
      stdout_logger.info msg
    }
    logger=nil
    stdout_logger=nil

    # verify

    parser = ChainLog::Parser.new
    err,num_lines = parser.verify_file(TEMP_LOG)
    assert err===false, err
    assert_equal 6,num_lines
  end

end
