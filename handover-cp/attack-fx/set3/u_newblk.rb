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
a.map { |x| c = W.new; c = x; c.then; 1 }
puts "done"
