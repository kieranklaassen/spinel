# `x != y` on a boxed x asks the class's own !=, as its == is asked.
class Tok
  attr_reader :v
  def initialize(v) = @v = v
  def !=(o) = true
end
class Base
  def !=(o) = false
end
class Kid < Base; end
class Plain; end

t = Tok.new(1)
xs = [t, 3, "s", nil]
p xs[0] != xs[0]
p xs.map { |x| x != t }
p xs.map { |x| x != 3 }
ys = [Kid.new, Plain.new, 3]
p ys.map { |y| y != 3 }
p ys.map { |y| y != ys[1] }

# a raised exception of a class with its own !=, under either box
class MyErr < StandardError
  def !=(o) = true
end
k = MyErr.new("n")
ks = [k, 3]
begin
  raise k
rescue => e
  p e != ks[0], ks[0] != e, ks[0] != ks[0], e != e
end
