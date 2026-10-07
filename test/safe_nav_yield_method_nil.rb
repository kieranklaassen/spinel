# A `&.` call, with a block, of a method that yields: on a nil receiver
# neither the method nor the block runs. The method's body is spliced in
# place of the call, and it was spliced ahead of the nil guard; as a
# statement on a receiver of several classes the nil raised NoMethodError.
$c = 0
class K
  def blk(a); $c += 1; yield(a); end
  def b0; $c += 1; yield; end
  def each; $c += 1; [1, 2].each { |x| yield x }; self; end
end
def mk(v) = v ? K.new : nil
def tail(o) = o&.blk(5) { |q| q + 1 }
def ret(o); return o&.blk(5) { |q| q + 1 }; end
def last(o)
  $c += 100
  o&.blk(5) { |q| $c += 10 }
end

o = mk(false)
r = o&.blk([1, 2]) { |q| q.size }
p r, $c
o&.blk(1) { |q| $c += 10 }
p $c
p o&.b0 { 5 }, $c
o&.each { |x| $c += 10 }
z = o&.each { |x| $c += 10 }
p z.nil?, $c
p tail(o), ret(o), last(o), $c
if o&.blk(1) { |q| q } then puts "y" else puts "n" end
puts "<#{o&.blk(1) { |q| q }}>"
[1, 2].each { |i| o&.blk(i) { |q| $c += 10 } }
p $c

# the receiver is evaluated once
def mk2(v); $c += 1000; v ? K.new : nil; end
mk2(false)&.blk(1) { |q| $c += 10 }
p $c
p mk2(false)&.blk(1) { |q| q }, $c
mk2(true)&.blk(1) { |q| $c += 10 }
p $c

# a receiver that is not nil runs the method and the block
o = mk(true)
p o&.blk([1, 2]) { |q| q.size }, $c
o&.blk(1) { |q| $c += 10 }
p $c
p tail(o), ret(o), $c
o&.each { |x| $c += 10 }
p $c

# a receiver of several classes, as a statement
x = [K.new, nil, 3][1]
x&.blk(5) { |q| $c += 10 }
p $c
h = { 1 => K.new }
h[2]&.blk(5) { |q| $c += 10 }
p $c
[mk2(true), mk2(false)][1]&.blk(1) { |q| $c += 10 }
p $c
x = [K.new, nil, 3][0]
x&.blk(5) { |q| $c += 10 }
h[1]&.blk(5) { |q| $c += 10 }
p $c
