require 'minitest/autorun'
require 'chainlog'
require 'active_support'
require 'json'

class FormatterTest < Minitest::Test

  TEMP_LOG='./test/fff123.log'
  MULTILINE_LOG='./test/excep_log'

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
      uno = parser.parse_and_validate_line(lines[1])
      assert_equal 'W', uno.severity
      assert_equal ChainLog::Formatter.hash_str(''), uno.hash
    }

    parser = ChainLog::Parser.new
    parser.parse_file(TEMP_LOG) { |line, entry|
      assert !(entry.hash_chain_broken?), "Invalid chain on line #{line}"
    }

    parser = ChainLog::Parser.new
    err,num_lines = parser.verify_file(TEMP_LOG)
    assert err===false, err
    assert_equal 3,num_lines

  end

  def test_validate
    str = <<-EOS
W 2016-05-13T16:02:06.200431 [19760,,1dc,1,b855] : hola
E 2016-05-13T16:02:06.200489 [19760,,1dc,2,5bd7] : something gone wrong {"a":1,"b":"32233"}
I 2016-05-13T16:02:06.200510 [19760,,1dc,3,b4ea] : {"a":1,"b":"32233"}
EOS

    parser = ChainLog::Parser.new
    str.split("\n").each { |line|
      entry = parser.parse_and_validate_line line
      assert !entry.nil?, "parse error on line #{line}"
      assert !entry.hash_chain_broken?, "Hash chain broken on line #{line}"
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
    assert_equal 5,num_lines
  end

  # a log where multiple processes, and therefore more than one formatter instance writing to log
  def test_mult_pids
    # NOTE: If this test is failing, make sure your IDE did not strip off trailing space on the two 'D' lines below
    str =<<-EOS
I 2016-05-13T16:06:02.702771 [19893,,16c,2,6435] :   Parameters: {"flash"=>"false"}
I 2016-05-13T16:06:02.705831 [19893,,16c,3,58fb] : Completed 200 OK in 3ms (Views: 0.4ms | ActiveRecord: 0.0ms)
D 2016-05-13T16:06:03.193366 [19892,,d84,5,f82f] : 
D 2016-05-13T16:06:03.193544 [19892,,d84,6,9b54] : 
I 2016-05-13T16:06:03.193710 [19892,,d84,7,3e40] : Started GET "/" for ::1 at 2016-05-13 16:06:03 -0500
EOS
    parser = ChainLog::Parser.new
    str.split("\n").each { |line|
      entry = parser.parse_and_validate_line line
      assert !entry.nil?, "Parse error on line #{line}"
      assert !entry.hash_chain_broken? ,"Invalid chain on line #{line}"
    }
  end

  def test_multi_line
    parser = ChainLog::Parser.new
    err,num_lines = parser.verify_file(MULTILINE_LOG)
    assert err===false, err
    assert_equal 5,num_lines

  end

end
