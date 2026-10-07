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
x = ARGV.size > 5 ? d : v
p(x.freeze)
a = [x.freeze]
p a.size
h = { k: x.freeze }
p h[:k].nil?
puts "#{x.freeze.nil?}"
p $n
