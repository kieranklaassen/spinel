# A String variable `initialize` stores in an instance variable, mutated in
# place through the variable, and read back through the attribute reader.
# Refused.
class Line
  attr_reader :text
  def initialize(text)
    @text = text
  end
end
buf = +"alpha"
line = Line.new(buf)
buf.upcase!
puts line.text
