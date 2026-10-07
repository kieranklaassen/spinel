class W
  def initialize; @n = 0; end
  def n; @n; end
  def me = self
  def then
    @n += 1
    self
  end
end
def each2; yield 1; end
b = W.new
c = W.new
each2 { |i| b = c.me }
b.then
puts "done"
