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
l = -> { a.map { |x| b = x; 1 } }
l.call
b.then
puts "done"
