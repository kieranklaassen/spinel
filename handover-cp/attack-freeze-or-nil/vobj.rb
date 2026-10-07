$n = 0
class Pt
  def initialize(a); @a = a; end
  def a; @a; end
  def freeze
    $n += 1
    self
  end
end
q = Pt.new(3)
v = nil
x = ARGV.size > 5 ? q : v
y = x.freeze
p y.class
z = ARGV.size < 5 ? q : v
w = z.freeze
p w.a
p $n
