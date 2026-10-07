class W
  def initialize; @n = 0; end
  def n; @n; end
  def then
    @n += 1
    puts "own then ran"
    self
  end
end
def pick(f) = f ? W.new : nil
def holes
  a = [W.new]
  a[2] = W.new
  a
end
class V
  def self.new(f) = f ? super() : nil
  def then = puts("V then")
end
b = V.new(ARGV.size > 0)
b.then
puts "done"
