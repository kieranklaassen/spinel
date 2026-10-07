# CRuby has a Set before the program runs, so `class Set` reopens it: its
# objects have Set's to_a, and a splatted one is spread, here to nothing.
# Spinel compiles a class of the program's own, and such a program keeps the
# form a splatted object had (test/splat_object_into_method.rb): the call
# raises, in CRuby for the argument that is missing, in spinel for the Array
# the object is wrapped in.
class Set
  def n = 1
end

def num(a) = a.n

x = Set.new
begin
  p num(*x)
rescue ArgumentError, NoMethodError
  puts "raised"
end
