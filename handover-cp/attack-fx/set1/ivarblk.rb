class W
  def initialize; @n = 0; end
  def n; @n; end
  def then
    puts "own then ran"
    self
  end
end
def pick(f) = f ? W.new : nil
class H
  def initialize(a); @w = W.new; a.each { |b| @w = b }; end
  def go; @w.then; end
end
a = [W.new]
a << pick(ARGV.size > 0)
H.new(a).go
puts "done"
