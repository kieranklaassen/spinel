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
def go(b)
  b.then
  1
end
a.map { |x| go(x) }
puts "done"
