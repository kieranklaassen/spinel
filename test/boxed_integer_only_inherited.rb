# odd? and even? defined where an Integer inherits them: an Integer in the
# box still answers Integer's own, and a Float reaches Numeric's.
class Object
  def odd? = false
end
module Kernel
  def even? = true
end
class Numeric
  def odd? = to_i.odd?
end

v = [7, "s"][ARGV.size]
p v.odd?
p v.even?
w = [8, "s"][ARGV.size]
p w.odd?
p w.even?
f = [3.5, "s"][ARGV.size]
p f.odd?
p [1, 2, 3].map { |e| [e, "s"][ARGV.size].odd? }
