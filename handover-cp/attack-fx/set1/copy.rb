class W
  def initialize; @n = 0; end
  def n; @n; end
  def then
    puts "own then ran"
    self
  end
end
def pick(f) = f ? W.new : nil
a = [W.new]
a << pick(ARGV.size > 0)
a.each { |b| c = b; c.then }
puts "done"
