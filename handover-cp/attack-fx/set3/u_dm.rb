class W
  def initialize; @n = 0; end
  def n; @n; end
  def then
    @n += 1
    self
  end
end
a = [W.new]
a[2] = W.new
a.pop
class H
  define_method(:go) do |a|
    b = W.new
    a.map { |x| b = x; 1 }
    b.then
    1
  end
end
H.new.go(a)
puts "done"
