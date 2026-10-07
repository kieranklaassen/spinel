# A class carried by name (an exception's class, a String or Float Range's,
# a Random's) is itself where the program's first class is a keyword_init
# Struct, or any class with a `new` of its own.
S = Struct.new(:x, keyword_init: true)

begin
  raise ArgumentError, "x"
rescue => e
  p e.class
  puts e.class.inspect
  puts "got #{e.class.inspect}: #{e.message}"
  f = e.class.new("z")
  p f.message
  p e.class == ArgumentError, e.class == S
  k = e.class
  p k
end

begin
  1 / 0
rescue => e
  p e.class
end

begin
  { a: 1 }.fetch(:b)
rescue => e
  p e.class
end

begin
  raise "x"
rescue
  p $!.class
end

def cls_of
  raise TypeError, "t"
rescue => e
  e.class
end
p cls_of
puts cls_of.inspect

r = Random.new(1)
p r.class
puts r.class.inspect
puts ("a".."c").class.inspect, (1.0..2.0).class.inspect

# the Struct's own class keeps its suffix
p S
p S.new(x: 1).x
