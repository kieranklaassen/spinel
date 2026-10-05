# A fold seeded with an empty [] whose block answers the memo at every step
# has that Array for its memo, whatever the receiver holds. The memo was
# typed as the receiver's element, so over Strings `m << v << s` read as a
# String append and `s` went in as a copy.

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

# the String in the middle of the chain
s6 = +"s"
x6 = ["a"].inject([]) { |m, v| m << v << s6 << v }
s6 << "x"
p x6

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
s11 = +"s"
x11 = [1, 2].inject([]) { |m, v| m << v << s11 }
s11 << "x"
p x11

# through a conditional
s8 = +"s"
x8 = ["a", "b"].inject([]) { |m, v| m.empty? ? m << v << s8 : m }
s8 << "x"
p x8

# what these already did stays
s9 = +"s"
x9 = ["a"].inject([]) { |m, v| m << s9 << v }
s9 << "x"
p x9

s10 = +"s"
x10 = ["a"].inject([]) { |m, v| m << v; m << s10 }
s10 << "x"
p x10

p ["a"].inject([]) { |m, v| m << v << v }
p [1, 2].inject([]) { |m, v| m << v << v }
p ["a", "b"].inject(+"") { |m, v| m << v << "-" }
p [1, 2].inject(1) { |m, v| m << v << 1 }
