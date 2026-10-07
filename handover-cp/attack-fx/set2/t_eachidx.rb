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
a.each_with_index { |x, i| b = x if i == 1 }
b.then
puts "done"
