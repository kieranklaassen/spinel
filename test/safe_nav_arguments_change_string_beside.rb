# A String is changed by assigning its variable (`s << "x"`), so a read of
# it beside a `&.` call whose arguments change it comes after them. Those
# arguments are made ahead of the statement, not under the nil test, where
# the read would stand in one C expression with the assignment.
class K
  attr_accessor :w
  def name(a) = 7
  def keep(a) = a
end
def two(a, b) = "#{a}|#{b}"
def two2(a, b) = [a, b]
def app(x) = (x << "x"; 1)
def go(s) = two(s, $last&.name((s << "x"; 1)))
$last = K.new

# the String before the call, each way of changing it
a1 = +"ab"; r1 = two(a1, $last&.name((a1 << "x"; 1))); p r1, a1
a2 = +"ab"; r2 = two(a2, $last&.name((a2.concat("x"); 1))); p r2
a3 = +"ab"; r3 = two(a3, $last&.name((a3.upcase!; 1))); p r3
a4 = +"ab"; r4 = two(a4, $last&.name((a4.replace("q"); 1))); p r4
a5 = +"ab"; r5 = two(a5, $last&.name((a5[0] = "x"; 1))); p r5
a6 = +"ab"; r6 = two(a6, $last&.name((a6.clear; 1))); p r6

# changed by a method, by a lambda, through a second name, in a method
b1 = +"ab"; r7 = two(b1, $last&.name(app(b1))); p r7
b2 = +"ab"; f = -> { b2 << "x"; 1 }; r8 = two(b2, $last&.name(f.call)); p r8
b3 = +"ab"; b4 = b3; r9 = two(b3, $last&.name((b4 << "x"; 1))); p r9, b4
b5 = +"ab"; p go(b5), b5

# the String is the receiver of the call around
c1 = +"ab"; r10 = c1.center(6, $last&.keep((c1 << "x"; "*"))); p r10
c2 = +"ab"; r11 = (c2 == ($last&.keep((c2 << "x"; "abx")))); p r11
c3 = +"ab"; r12 = c3 + ($last&.keep((c3 << "x"; "!")) || ""); p r12

# the String after the call
d1 = +"ab"; r13 = two2($last&.name((d1 << "x"; 1)), d1); p r13

# in the value of a writer and of an index assignment
k = K.new
e1 = +"ab"; k.w = two(e1, $last&.name((e1 << "x"; 1))); p k.w
a = [nil]
e2 = +"ab"; a[0] = two(e2, $last&.name((e2 << "x"; 1))); p a

# and it is still alive: the appended String is the one the call is given
bad = 0
3000.times do |i|
  s = "ab#{i}"
  r = two(s, $last&.name((s << "x" * 40; [K.new, "q#{i}" * 4])))
  bad += 1 unless r == "ab#{i}" + "x" * 40 + "|7"
end
p bad
