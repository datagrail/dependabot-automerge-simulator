require 'minitest/autorun'
require_relative 'app'

class TestApp < Minitest::Test
  def test_arithmetic
    assert_equal 2, 1 + 1
  end

  def test_string
    assert_equal 'HELLO', 'hello'.upcase
  end

  def test_static_server_initializes
    server = StaticServer.new(Dir.pwd)
    assert_respond_to server, :call
  end
end
