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
b = W.new
c = a.map { |x| x }
b = c[1] if c.size > 5
c.map { |x| b = x if x.nil?; 1 }
b.then
puts "done"
