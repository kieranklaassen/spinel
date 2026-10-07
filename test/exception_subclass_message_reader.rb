# `attr_reader :message` in an exception class of the program's own is
# Exception#message for that class, as a `def message` is: a rescue reads
# it, and so does a caller that knows the exception only as a StandardError.
class ParseError < StandardError
  attr_reader :message, :line
  def initialize(text, line)
    super("parse error")
    @message = "#{text} at line #{line}"
    @line = line
  end
end
begin
  raise ParseError.new("unexpected end", 3)
rescue ParseError => e
  p e.message, e.line
end
begin
  raise ParseError.new("bad token", 7)
rescue StandardError => e
  puts "#{e.class}: #{e.message}"
end
def boxed(i) = i > 0 ? ParseError.new("stray", 1) : "none"
b = boxed(1)
p b.message if b.is_a?(StandardError)
errs = [ParseError.new("a", 1), RuntimeError.new("plain")]
errs.each { |x| puts x.message }

# attr_accessor: the reader is the message, the writer sets what it reads
class Tagged < RuntimeError
  attr_accessor :message
  def initialize(m)
    super(m)
    @message = "tagged: " + m
  end
end
begin
  raise Tagged.new("x")
rescue Tagged => e
  p e.message
  e.message = "set"
  p e.message
end

# a class under another class of the program, in a namespace, and a
# subclass that inherits the reader
module Net
  class Error < StandardError; end
  class Timeout < Error
    attr_reader :message
    def initialize(secs)
      super("timeout")
      @message = "timed out after #{secs}s"
    end
  end
end
class Slow < Net::Timeout; end
begin
  raise Slow.new(5)
rescue Net::Timeout => e
  puts "#{e.class}: #{e.message}"
end

# Exception#to_s is not the reader
t = Tagged.new("y")
p t.to_s, t.message

# as before: a def message, a class that defines both, a class that is no
# exception
class Own < StandardError
  def initialize(m) = @m = m
  def message = "own: " + @m
end
begin
  raise Own.new("z")
rescue => e
  p e.message
end
class Both < StandardError
  attr_reader :message
  def initialize(m) = @message = m
  def message = "def wins"
end
p Both.new("q").message
class Note
  attr_reader :message
  def initialize(m) = @message = m
end
p Note.new("plain").message
