# `&.` on a receiver that is nil alone runs none of the call: tap, then and
# yield_self ran their block on the nil, and a tap that is a statement of a
# method did not build.
$n = 0
def none; $n += 1; nil; end
def t; nil&.tap { $n += 10 }; end
def hid; nil&.then { $n += 100; 1 }; end

nil&.then { $n += 10 }
p $n
p hid, $n
x = nil&.tap { $n += 100 }
p x, $n
p t, $n
p nil&.yield_self { |v| $n += 100; v }
p $n
z = nil
p z&.then { |v| $n += 100; 7 }
p $n
if nil&.tap { $n += 100 }
  puts "y"
else
  puts "n"
end
p !(nil&.then { $n += 100; 1 })
p $n

# a receiver that is more than a read is evaluated, once
none&.tap { $n += 10 }
p $n
y = none&.then { |v| $n += 10; 7 }
p y, $n
a = [none&.tap { |v| $n += 10 }, 1]
p a, $n
puts "<#{none&.yield_self { $n += 10 }}>"
p $n

# a receiver that is such a call, or a `&.` call whose guard is taken
none&.tap { $n += 100 }&.then { $n += 100 }
p $n
class O
  def bar; $n += 1; nil; end
end
def mk(v) = v ? O.new : nil
o = mk(true)
o&.bar&.tap { $n += 100 }
p $n
q = mk(false)
p q&.bar&.then { $n += 100; 1 }, $n

# a plain call on nil runs its block
p nil.then { 5 }
w = nil.tap { $n += 1000 }
p w, $n
p nil.yield_self { |v| v.inspect }
