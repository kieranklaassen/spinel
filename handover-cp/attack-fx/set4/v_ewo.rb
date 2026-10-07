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
[1].each_with_object([]) { |i, m| b = c.me }
b.then
puts "done"
