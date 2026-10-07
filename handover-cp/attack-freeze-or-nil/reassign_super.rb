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
x = ARGV.size > 5 ? d : v
x = x.freeze
p x.class
x = ARGV.size < 5 ? d : v
x = x.freeze
p x.class
p $n
