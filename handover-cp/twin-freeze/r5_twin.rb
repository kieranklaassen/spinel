$n = 0
class Doc
  def freeze
    $n += 1
    self
  end
end
class Cart
  def freeze
    $n += 10
    self
  end
end
d = Doc.new
k = Cart.new
v = nil
x = ARGV.size < 5 ? d : v
y = x
p y.class
p $n
