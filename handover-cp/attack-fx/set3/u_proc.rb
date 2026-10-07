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
pr = proc { |x| b = x }
a.map { |x| pr.call(x); 1 }
b.then
puts "done"
