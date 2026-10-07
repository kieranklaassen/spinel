# A fold seeded with an empty [] whose block is one chain of pushes onto the
# memo, ending in a variable from outside the block, has that Array for its
# memo, whatever the receiver holds. The memo was typed as the receiver's
# element, so over Strings `m << v << s` read as a String append and `s`
# went in as a copy.

s1 = String.new
x1 = ["a"].inject([]) { |m, v| m << v << s1 }
s1 << "x"
p x1

s2 = +"s"
x2 = ["a", "b"].reduce([]) { |m, v| m << v << s2 }
s2 << "x"
p x2

s3 = +"s"
x3 = ["a"].inject([]) { |m, v| (m << v) << s3 }
s3.upcase!
p x3

s4 = +"s"
x4 = ["a"].inject([]) { |m, v| m.push(v).push(s4) }
s4 << "x"
p x4

s5 = +"s"
x5 = ["a"].inject([]) { |m, v| m << v << v << s5 }
s5 << "x"
p x5

s6 = +"s"
x6 = ["a"].inject([]) { |m, v| m.append(v) << s6 }
s6 << "x"
p x6, x6[1].equal?(s6)

# over a local, and in a method
s7 = +"s"
w7 = ["a", "b"]
x7 = w7.inject([]) { |m, v| m << v << s7 }
s7 << "x"
p x7

def chained
  s = String.new
  x = ["a"].inject([]) { |m, v| m << v << s }
  s << "x"
  x
end
p chained

# over Integers, where the chain read as a shift
s8 = +"s"
x8 = [1, 2].inject([]) { |m, v| m << v << s8 }
s8 << "x"
p x8

# a variable that is no String
n9 = 5
p [1, 2].inject([]) { |m, v| m << v << n9 }
r9 = [1]
x9 = ["a"].inject([]) { |m, v| m << v << r9 }
r9 << 2
p x9

# what these already did stays
s10 = +"s"
x10 = ["a"].inject([]) { |m, v| m << s10 << v }
s10 << "x"
p x10

s11 = +"s"
x11 = ["a"].inject([]) { |m, v| m << v; m << s11 }
s11 << "x"
p x11

p ["a"].inject([]) { |m, v| m << v << v }
p [1, 2].inject([]) { |m, v| m << v << v }
p ["a", "b"].inject(+"") { |m, v| m << v << "-" }
p [1, 2].inject(1) { |m, v| m << v << 1 }
