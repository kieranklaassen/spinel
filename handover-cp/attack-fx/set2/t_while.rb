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
i = 0
while i < 1
  a.map { |x| b = x if x.nil?; 1 }
  i += 1
end
b.then
puts "done"
