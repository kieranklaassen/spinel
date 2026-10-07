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
def fz(x) = x.freeze
def pick(f, a, b) = f ? a : b
p fz(pick(false, d, v)).nil?
p fz(pick(true, d, v)).equal?(d)
p fz(5)
p $n
