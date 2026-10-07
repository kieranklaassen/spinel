$n = 0
class Doc
  def initialize; @s = 1; end
  def s; @s; end
  def freeze
    $n += 1
    self
  end
end
d = Doc.new
v = nil
i = 0
while i < 3
  x = i > 5 ? d : v
  y = x.freeze
  p y.inspect
  v = "s" if i == 1
  i += 1
end
p $n
