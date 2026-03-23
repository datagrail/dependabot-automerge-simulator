require 'minitest/autorun'

class TestHello < Minitest::Test
  def test_arithmetic
    assert_equal 2, 1 + 1
  end

  def test_string
    assert_equal 'HELLO', 'hello'.upcase
  end
end
