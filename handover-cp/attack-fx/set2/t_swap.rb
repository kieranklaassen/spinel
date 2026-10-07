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
c = W.new
a.map { |x| c = x if x.nil?; 1 }
b = c
b.then
puts "done"
