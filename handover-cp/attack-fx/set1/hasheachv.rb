class W
  def initialize; @n = 0; end
  def n; @n; end
  def then
    puts "own then ran"
    self
  end
end
def pick(f) = f ? W.new : nil
h = { a: W.new }
h[:b] = pick(ARGV.size > 0)
h.each_value { |v| v.then }
puts "done"
