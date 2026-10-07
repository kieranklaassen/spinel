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
begin
  p x.freeze.s
rescue NoMethodError => e
  p e.class
end
p $n
