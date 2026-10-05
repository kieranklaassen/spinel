# An argument that assigns a local runs before a later argument that reads
# it, as CRuby evaluates arguments left to right: `f((n = 5; 1), n)` binds
# [1, 5]. The two used to sit side by side in one C argument list, whose
# order C leaves open, and gcc read the local first: into a boxed parameter,
# for `n + 0`, for a builtin's operand. `[n]` and an interpolation were
# built ahead of the whole call, so they held the old value under clang too.
def f(a, b) = [a, b]
def f3(a, b, c) = [a, b, c]
def g(a, b) = [a, b]
def kw(a:, b:) = [a, b]
def kp(a, b:, c: 0) = [a, b, c]
def opt(a, b = 7, c = 9) = [a, b, c]
def rest(*r) = r
def blk(a, b) = yield(a, b)
def in_yield
  n = 3
  yield((n = 5; 1), n)
end
def in_method
  n = 3
  r = f((n = 5; 1), n)
  [r, n]
end

class K
  attr_reader :a, :b
  def initialize(a, b) = (@a = a; @b = b)
  def m(a, b) = [a, b]
  def self.cm(a, b) = [a, b]
end

class L < K
  def initialize(n) = super((n = 5; 1), n)
end

class Q
  attr_reader :v
  def initialize(v) = @v = v
end

H = Struct.new(:n, :x)
HK = Struct.new(:n, :x, keyword_init: true)
D = Data.define(:n, :x)

# the later parameter boxed: every caller's class in one slot
f(1, "s"); K.new(1, "s"); K.cm(1, "s"); H.new(1, "s"); D.new(1, "s"); HK.new(n: 1, x: "s")
kw(a: 1, b: "s"); opt(1, "s"); rest(1, "s"); blk(1, "s") { |a, b| [a, b] }

# a method, a class method, a constructor, a Struct and a Data
n = 3; p f((n = 5; 1), n)
n = 3; p K.cm((n = 5; 1), n)
n = 3; p K.new((n = 5; 1), n).b
n = 3; p H.new((n = 5; 1), n).x
n = 3; p HK.new(n: (n = 5; 1), x: n).x
n = 3; p D.new((n = 5; 1), n).x
n = 3; p D.new(n: (n = 5; 1), x: n).x
n = 3; p K.new(0, 0).m((n = 5; 1), n)
# keywords, an optional, a rest, a block, a yield and a super
n = 3; p kw(a: (n = 5; 1), b: n)
n = 3; p kp((n = 5; 1), b: n)
n = 3; p kp(0, b: (n = 5; 1), c: n)
n = 3; p opt((n = 5; 1), n)
n = 3; p opt((n = 5; 1), n, n)
n = 3; p rest((n = 5; 1), n)
n = 3; p(blk((n = 5; 1), n) { |a, b| [a, b] })
p(in_yield { |a, b| [a, b] })
p L.new(3).b
p in_method
# the read inside a value: unboxed parameters, where the bare read was right
n = 3; p g((n = 5; 1), n)
n = 3; p g((n = 5; 1), n + 0)
n = 3; p g((n = 5; 1), n * 2)
n = 3; p f((n = 5; 1), [n])
n = 3; p f((n = 5; 1), "<#{n}>")
n = 3; p f((n = 5; 1), [0].map { |i| i + n })
# the assignment in other spellings
n = 3; p f(n = 5, n)
n = 3; p f((n += 2), n)
n = 3; p f(begin; n = 5; 1; end, n)
n = 3; p f((n = 5 if n == 3; 1), n)
n = 3; m = 4; p f((n, m = 5, 6; 1), n + m)
n = 3; p f((n = 5; 1).itself, n)
n = 3; p f(1.tap { n = 5 }, n)
# a String, a Float, an Array and an object
t = "a"; p f((t = "b"; 1), t)
t = "a"; p K.new((t = "b"; 1), t).b
t = "a"; p H.new((t = "b"; 1), t).x
x = 1.5; p f((x = 2.5; 1), x)
a = [3]; p f((a = [5]; 1), a)
o = Q.new(3); p f((o = Q.new(5); 1), o).last.v
# reads on both sides of the assignment, and two assignments
n = 3; p f3(n, (n = 5; 1), n)
n = 3; m = 3; p f3((n = 5; 1), (m = 6; 2), [n, m])
n = 3; p f3((n = 5; 1), n, (n = 7; 2)); p n
n = 3; p f(f((n = 5; 1), n).size, n)
# a lambda that assigns the local it shares
n = 3; la = -> { n = 5; 1 }; p f(la.call, n)
# where the call does not run, neither does the assignment
n = 3; c = false; p(c && f((n = 5; 1), n)); p n
n = 3; c = true; p(c ? f((n = 5; 1), n) : 0); p n
2.times { n = 3; p f((n = 5; 1), n) }
i = 0; while i < 2; n = 3; p f((n = 5; 1), n + i); i += 1; end

# a builtin's operands
t = "a"; p "x".rjust((t = "b"; 5), t)
t = "a"; p "x".ljust((t = "b"; 5), t)
t = "a"; p "x".center((t = "b"; 5), t)
t = "a"; p "xax".gsub((t = "x"; "a"), t)
t = "a"; p "xax".sub((t = "x"; "a"), t)
t = "a"; p "xax".tr((t = "x"; "a"), t)
t = "a"; p File.join((t = "b"; "c"), t)
n = 3; p "abcdefgh"[(n = 5; 1), n + 0]
n = 3; p "abcdefgh".byteslice((n = 5; 1), n + 0)
n = 10; p Integer((n = 16; "ff"), n + 0)
n = 3; p 2.pow((n = 5; 3), n + 0)
n = 3; p 4.clamp((n = 5; 1), n + 0)
n = 3; p 4.between?((n = 5; 1), n + 0)
x = 1.0; p Math.hypot((x = 3.0; 4.0), x + 0.0)
n = 3; p [1, 2, 3].insert((n = 5; 1), n + 0)
n = 3; p [1, "s", 2, 3].insert((n = 5; 1), n + 0)
n = 0; p [[1, 2], [3, 4]].dig((n = 1; 0), n + 0)
o = Q.new(1); p [Q.new(0)].insert((o = Q.new(5); 1), o).map(&:v)
# the receiver is an operand too
t = "a"; p((t = "b"; "c") + t)
t = "a"; p((t = "b"; "b") == t)
t = "a"; p((t = "b"; "x").rjust(3, t))
t = "a"; p "abc".tr((t = "b"; "a"), t).sub((t = "c"; "b"), t)

# The assignment runs at its call, not ahead of the statement: a read to the
# left of the call is the old value
n = 3; p "#{n} #{f((n = 5; 1), n)}"
n = 3; p [n, f((n = 5; 1), n), n]
n = 3; x, y = n, f((n = 5; 1), n); p x, y
n = 3; p n * 100 + f((n = 5; 1), n).sum
n = 3; p n, f((n = 5; 1), n), n
t = "a"; p "#{t} #{"x".rjust((t = "b"; 5), t)}"
def ss(a, b) = a + b
t = "a"; p t + ss((t = "b"; "c"), t) + t
p(in_yield { |a, b| "#{a} #{b}" } + in_method.inspect)
def left_of_yield
  n = 3
  "#{n} #{yield((n = 5; 1), n)} #{n}"
end
p(left_of_yield { |a, b| [a, b] })
class L2 < K
  def m(a, b)
    n = 3
    "#{n} #{super((n = 5; a), n)} #{n}"
  end
end
p L2.new(0, 0).m(1, 2)
# ... and a call that a test in front of it skips assigns nothing
n = 3; p(case 7 when 7 then 0 when f((n = 5; 1), n).first then 1 end); p n
n = 3; p(case 1 when 7 then 0 when f((n = 5; 1), n).first then 1 end); p n
$g = 1; n = 3; $g ||= f((n = 5; 1), n); p $g, n
$h = nil; n = 3; $h ||= f((n = 5; 1), n); p $h, n
t = "a"; s = [nil, "x"].first; p s&.rjust((t = "b"; 5), t); p t
t = "a"; s = [nil, "x"].last; p s&.rjust((t = "b"; 5), t); p t
# a builtin's one operand that assigns, with a later operand built ahead of
# the call: that one is built after the assignment
n = 3; p [(n = 5)].dup.concat([n])
n = 3; p [(n = 5)].dup.concat([n], [n + 1])
h = {}; h.update((k = :a) => 1).update(k => 2); p h.to_a
t = "a"; p [(t = "b")].dup.push("#{t}!")
# one to its left that reads the local keeps the old value, and a chain of
# appends appends once
n = 3; p [n].concat([(n = 5)].dup, [n])
buf = +"z"; x = buf << (c = "q") << c; p buf, x.equal?(buf)
