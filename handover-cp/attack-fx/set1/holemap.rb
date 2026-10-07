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
holes.map { |b| b.then; 1 }
puts "done"
