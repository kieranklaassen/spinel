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
3.times do |i|
  x = i == 1 ? d : v
  y = x.freeze
  p y.class
  v = 5 if i == 1
end
p $n
