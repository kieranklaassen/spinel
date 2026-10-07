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
y = x&.freeze
p y.nil?
z = ARGV.size < 5 ? d : v
w = z&.freeze
p w.equal?(d)
p $n
