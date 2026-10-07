# A method that yields is inlined where it is called with a block, its
# locals under names of their own. Inside a proc's body the question "is
# this name one the proc captures" was asked of the bare name first, so the
# method's `nn` read, and wrote, the proc's captured `nn`. Each case has
# methods and variables of its own.

# a parameter read
def twice1(nn)
  yield nn * 2
end
nn = 10
g1 = -> { twice1(3) { |v| v + nn } }
p g1.call
nn += 1
p g1.call

# a local written: the caller's variable keeps its value
def twice2(a)
  m = a * 2
  yield m
end
m = 10
g2 = -> { m += 1; twice2(3) { |v| v + 1 } }
p g2.call, m

# `+=`, `||=`, a multiple assignment, the value of a write
def bump3(c)
  c += 1
  d = nil
  d ||= c * 2
  c, d = d, c
  yield(c += d)
end
c = 100
d = 1000
g3 = proc { c += 1; bump3(3) { |v| v + c + d } }
p g3.call, c, d

# a loop's counters
def sum4(k)
  i = 0
  s = 0
  while i < k
    i += 1
    s += yield(i)
  end
  s
end
i = 100
s = 1000
g4 = -> { sum4(3) { |v| v + i + s } }
p g4.call, i, s

# a String the method appends to, and one it lends to an appender
def app5(t)
  t << "x"
  nil
end
def tag5(a)
  w = +"in"
  w << a
  app5(w)
  yield w
end
w = +"top"
g5 = -> { w << "!"; tag5("-") { |v| v + w } }
p g5.call, w

# a proc and a thread made inside the method capture the method's variable
def twice7(q)
  f = -> { q * 2 }
  t = Thread.new { q + 1 }
  yield f.call + t.value
end
q = 10
g7 = -> { q += 1; twice7(3) { |v| v + q } }
p g7.call, q

# a Proc held in a local of the method, under the name of the caller's Proc
def wrap8(a)
  h = -> { a * 2 }
  yield h.call
end
h = -> { 7 }
g8 = -> { wrap8(3) { |v| v + h.call } }
p g8.call

# a Proc of the method that calls itself (no proc around it is needed)
def wrap9(a)
  r = ->(k) { k <= 0 ? 0 : k + r.call(k - 1) }
  yield r.call(a)
end
p wrap9(3) { |v| v + 1 }
r = 100
g9 = -> { r += 1; wrap9(3) { |v| v + r } }
p g9.call, r

# keyword and default parameters, a rescued exception's name
def pick10(a, b = a + 1, z: 2)
  begin
    Integer("x")
  rescue => e
    b += e.class.name.size
  end
  yield a + b + z
end
a = 1000
b = 100
z = 10
e = 1
g10 = -> { pick10(3, z: 4) { |v| v + a + b + z + e } }
p g10.call

# a method inlined in a method inlined
def twice11(x)
  yield x * 2
end
def thrice11(x)
  twice11(x + 1) { |y| yield y + x }
end
x = 10
g11 = -> { thrice11(3) { |v| v + x } }
p g11.call

# a builtin's own parameter: max_by and min_by name theirs `n`
nums = [3, 1, 2]
n12 = 1
n = 1
g12 = -> { n += 1; [nums.max_by(1) { |v| -v }, nums.max_by { |v| -v }, nums.min_by(1) { |v| -v }] }
p g12.call, n, n12

# the proc is a lambda a method returns, a `Proc.new`, a block's own lambda
def twice13(j)
  yield j * 2
end
def make13(j)
  -> { twice13(3) { |v| v + j } }
end
p make13(10).call
j = 20
p Proc.new { twice13(4) { |v| v + j } }.call
p [1, 2].map { |o| -> { twice13(o) { |v| v + j } } }.map(&:call)

# as it was: a block that is no proc, a parameter that shadows the capture,
# a proc of the method alone
def twice14(l)
  yield l * 2
end
l = 10
[1].each { l += 1; p twice14(3) { |v| v + l } }
g14 = -> { got = []; [5, 6].each { |l| got << l }; [got, l] }
p g14.call
def twice15(y)
  f = -> { y * 2 }
  yield f.call
end
p twice15(3) { |v| v + 1 }
