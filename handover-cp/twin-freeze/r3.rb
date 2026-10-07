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
class Holder
  def initialize(x); @x = x; end
  def go; @x.freeze; end
end
p Holder.new(d).go.equal?(d)
p Holder.new(nil).go.nil?
p $n
