$n = 0
class Doc
  def initialize; @s = 1; end
  def s; @s; end
  def freeze
    $n += 1
    super
  end
end
d = Doc.new
v = nil
class Sub < Doc
end
s = Sub.new
x = ARGV.size < 5 ? s : v
y = x.freeze
p y.class
x2 = ARGV.size > 5 ? s : v
p x2.freeze.class
p $n
