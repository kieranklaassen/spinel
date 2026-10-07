class W
  def initialize; @n = 0; end
  def n; @n; end
  def then
    puts "own then ran"
    self
  end
end
def pick(f) = f ? W.new : nil
def firstof(a)
  a.each { |b| return b }
  W.new
end
a = [pick(ARGV.size > 0), W.new]
x = firstof(a)
x.then
puts "done"
