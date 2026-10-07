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
def other(a)
  b = nil
  a.map { |x| b = x if x.nil?; 1 }
  b
end
other(a)
b.then
puts "done"
