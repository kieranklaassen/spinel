class W
  def initialize; @n = 0; end
  def n; @n; end
  def then
    puts "own then ran"
    self
  end
end
def pick(f) = f ? W.new : nil
a = Array.new(2)
a[0] = W.new
a.each { |b| b.then }
puts "done"
