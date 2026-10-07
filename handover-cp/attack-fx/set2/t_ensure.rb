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
begin
  a.map { |x| b = x if x.nil?; 1 }
ensure
  b.then
end
puts "done"
