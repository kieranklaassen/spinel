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
b = W.new
i = 0
while i < 1
  holes.map { |x| b = x if x.nil?; 1 }
  i += 1
end
b.then
puts "done"
