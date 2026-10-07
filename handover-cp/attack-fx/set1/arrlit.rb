class W
  def initialize; @n = 0; end
  def n; @n; end
  def then
    puts "own then ran"
    self
  end
end
def pick(f) = f ? W.new : nil
a = [W.new, pick(ARGV.size > 0)]
a.each { |b| b.then }
puts "done"
