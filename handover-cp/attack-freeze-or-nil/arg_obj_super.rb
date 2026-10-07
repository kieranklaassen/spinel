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
x = ARGV.size < 5 ? d : v
a = [x.freeze]
p a.size
p a[0].equal?(d)
h = { k: x.freeze }
p h[:k].equal?(d)
puts "#{x.freeze.nil?}"
p $n
