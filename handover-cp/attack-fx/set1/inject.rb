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
x = a.inject { |m, b| b }
x.then
puts "done"
