class W
  def initialize; @n = 0; end
  def n; @n; end
  def me = self
  def then
    @n += 1
    self
  end
end
b = W.new
c = W.new
1.upto(1) { |i| b = c.me }
b.then
puts "done"
