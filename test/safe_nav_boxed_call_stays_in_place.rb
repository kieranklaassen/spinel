# A `&.` call on a value read out of a container runs in its place in the
# statement, also when its arguments are built or run ahead of it.
$c = 0
$log = []
def lg(x) = ($log << x; x)

class K
  def bump(a) = ($c += 1; a)
  def say(s) = puts(s)
  def two(a, b) = [a, b]
end
def bk(i) = [K.new, nil, 5][i]

b = bk(0)
z = bk(1)
p "#{$c} #{b&.bump([1, 2])}"
p "#{$c} #{z&.bump([1, 2])}"
x, y = $c, b&.bump([3])
p x, y
p [$c, b&.bump([4]), $c]
p [$c, z&.bump([4]), $c]
p [lg(0), b&.two(lg(1), [lg(2)]), lg(3)], $log
b&.say("hi")
z&.say("no")
r = b&.two([1], [2]) || []
p r.size

# below a method's top scope
[1, 2].each { |i| p "#{$c}:#{b&.bump([i])}" }
def m(v) = "#{$c} #{v&.bump([v.class.name])}"
p m(b), m(z)
def each2(v)
  2.times do |i|
    if i >= 0
      p "#{$c}/#{v&.bump([i, i])}"
    end
  end
end
each2(b)
each2(z)

