$n = 0
module Fz
  def freeze
    $n += 1
    super
  end
end
class Doc
  include Fz
end
d = Doc.new
v = nil
x = ARGV.size > 5 ? d : v
y = x.freeze
p y.class
z = ARGV.size < 5 ? d : v
w = z.freeze
p w.class
p $n
