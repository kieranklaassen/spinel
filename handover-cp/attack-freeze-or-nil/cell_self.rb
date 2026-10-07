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
blk = -> { v = 5 }
x = ARGV.size > 5 ? d : v
p x.freeze.class
blk.call
x2 = ARGV.size > 5 ? d : v
p x2.freeze.class
p $n
