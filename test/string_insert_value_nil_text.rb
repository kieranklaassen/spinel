# String#insert whose value is taken, with a text that is nil when the program
# runs: CRuby's TypeError, where the String came back as it was.

def none(k) = k == 1 ? +"one" : nil

m = +"abc"
begin
  p m.insert(1, none(2))
rescue TypeError => e
  puts e.message
end
p m.insert(1, none(1))
v = none(2)
x = begin
  m.insert(0, v)
rescue TypeError => e
  e.message
end
p x, m

# through a reader, and as a method's value
class Box
  attr_reader :buf
  def initialize = @buf = +"abc"
  def put(v) = @buf.insert(1, v)
end
b = Box.new
begin
  p b.buf.insert(1, none(2))
rescue TypeError => e
  puts e.message
end
begin
  p b.put(none(2))
rescue TypeError => e
  puts e.message
end
p b.put(none(1)), b.buf

# the nil ahead of an index outside the String and of a frozen String
begin
  p m.insert(99, none(2))
rescue => e
  p e.class
end
f = "abc"
begin
  p f.insert(1, none(2))
rescue => e
  p e.class
end

# a text that cannot be nil
p m.insert(1, "x"), (+"q").insert(0, "a" + "b")
