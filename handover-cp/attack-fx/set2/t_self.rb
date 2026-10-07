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
class W
  def dup; self.then; nil; end
end
a.map { |x| x.dup; 1 }
puts "done"
