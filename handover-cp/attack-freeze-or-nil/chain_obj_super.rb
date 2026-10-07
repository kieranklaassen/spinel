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
p x.freeze.frozen?
p x.freeze.nil?
p x.freeze.equal?(d)
p $n
