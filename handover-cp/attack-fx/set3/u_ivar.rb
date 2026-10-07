class W
  def initialize; @n = 0; end
  def n; @n; end
  def then
    @n += 1
    self
  end
end
a = [W.new]
a[2] = W.new
a.pop
class H
  def initialize(a)
    b = W.new
    a.map { |x| b = x; 1 }
    @r = b.then
  end
end
H.new(a)
puts "done"
