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
b = W.new
c = a.map { |x| x }
c.map { |x| b = x; 1 }
b.then
puts "done"
