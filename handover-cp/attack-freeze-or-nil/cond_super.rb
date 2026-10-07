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
if x.freeze
  p :truthy
else
  p :falsy
end
z = ARGV.size < 5 ? d : v
p(z.freeze ? :truthy : :falsy)
r = x.freeze || :none
p r
p $n
