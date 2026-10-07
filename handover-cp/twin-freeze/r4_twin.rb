$n = 0
class Doc
  def freeze
    $n += 1
    self
  end
end
class Sub < Doc
  def freeze
    $n += 10
    self
  end
end
s = Sub.new
v = nil
x = ARGV.size < 5 ? s : v
y = x
p y.class
p $n
