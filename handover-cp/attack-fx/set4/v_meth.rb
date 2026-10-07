class W
  def initialize; @n = 0; end
  def n; @n; end
  def me = self
  def then
    @n += 1
    self
  end
end
def go
  b = W.new
  c = W.new
  [1].each { |i| b = c.me }
  b.then
  1
end
go
puts "done"
