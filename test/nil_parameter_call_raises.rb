# A method called on a parameter that holds nil though no caller writes a
# plain nil argument -- a nil default, a keyword, a lambda's or a block's
# parameter, a nil written in the body, one handed on from such a
# parameter -- ran with a NULL self (answering as if the receiver were an
# instance) or crashed reading an ivar, where CRuby raises NoMethodError
# (#7262).
$stdout.sync = true
class Box
  attr_accessor :v

  def initialize(v)
    @v = v
  end

  def hello
    "hello"
  end

  def touch
    @v += 1
    nil
  end
end

# handed only by keyword
class Tag
  attr_reader :n

  def initialize(n)
    @n = n
  end
end

def try(label)
  yield
rescue NoMethodError => e
  puts "#{label}: #{e.message}"
end

def by_default(b = nil) = b.hello
def second(a, b = nil) = b.v + a
def by_keyword(b: nil) = b.v
def keyword_given(b:) = b.hello
def tag_of(t:) = t.n
def none = nil
def from_method(b = none) = b.hello
def inner(b) = b.hello
def outer(b = nil) = inner(b)

def reassigned(b = nil)
  b = Box.new(9) if ARGV.size > 5
  b.touch
  "touched"
end

def writer(b = nil)
  b.v = 3
end

def overwritten(b)
  b = nil if ARGV.size < 5
  b.hello
end

class Shelf
  def top(b = nil) = b.v
  def self.any(b: nil) = b.hello
end

def twice
  yield
  yield Box.new(7)
end

def each_then_nil
  yield Box.new(8)
  yield nil
end

try("default") { puts by_default }
puts by_default(Box.new(1))
try("second") { p second(1) }
p second(1, Box.new(2))
try("keyword default") { p by_keyword }
p by_keyword(b: Box.new(3))
try("keyword nil") { puts keyword_given(b: nil) }
puts keyword_given(b: Box.new(4))
try("keyword nil, attribute") { p tag_of(t: nil) }
p tag_of(t: Tag.new(5))
try("default from a method") { puts from_method }
puts from_method(Box.new(1))
try("handed on") { puts outer }
puts outer(Box.new(1))
try("statement") { puts reassigned }
puts reassigned(Box.new(1))
try("setter") { p writer }
p writer(Box.new(1))
try("written in the body") { puts overwritten(Box.new(1)) }
try("instance method") { p Shelf.new.top }
p Shelf.new.top(Box.new(6))
try("class method") { puts Shelf.any }
puts Shelf.any(b: Box.new(6))

greet = ->(b) { b.hello }
try("lambda") { puts greet.call(nil) }
puts greet.call(Box.new(1))
value = ->(b = nil) { b.v }
try("lambda default") { p value.call }
p value.call(Box.new(10))

try("block default") { twice { |b = nil| p b.v } }
try("yielded nil") { each_then_nil { |b| p b.v } }

# what nil answers itself is not an error
def asks(b = nil) = [b.nil?, b.inspect, b.to_s, b == nil]
p asks
def safely(b = nil) = b&.v
p safely
p safely(Box.new(11))
