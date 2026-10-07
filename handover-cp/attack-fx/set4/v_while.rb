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
i = 0
while i < 1
  b = c.me
  i += 1
end
b.then
puts "done"
