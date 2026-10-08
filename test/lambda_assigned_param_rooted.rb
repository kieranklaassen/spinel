# A proc reads its parameters out of the call's slots and clears the
# slots. A block's required parameter the body assigns is copied into a
# rooted local, and an optional and a keyword are rooted where they bind;
# a stabby lambda's required parameter and any proc's post were not, so
# nothing held what the body assigned to one while the body went on
# allocating.
B = ->(a) { a = a.to_s * 2; b = [1, 2]; [a, b] }
B.call("s")

# a plain run: two of the lambda's 2,000 answers held another String
keep = []
n = 0
while n < 2000
  keep << B.call(n)
  n += 1
end
bad = 0
keep.each_with_index { |v, i| bad += 1 unless v[0] == i.to_s * 2 }
p bad

# a boxed parameter: call, the dot and []
p B.call(12), B.("s"), B[4]

# a typed parameter: a String, an Array, a Hash, an object
S = ->(a) { a = a * 2; b = [1, 2]; [a, b] }
p S.call("s")
SO = ->(a) { a += "y" * 2; b = [1, 2]; [a, b] }
p SO.call("s")
A = ->(a) { a = a + [3]; b = [1, 2]; [a, b] }
p A.call([0])
H = ->(a) { a = a.merge({2 => 3}); b = [1, 2]; [a.keys, b] }
p H.call({0 => 0})
class Box
  def initialize(v) = @v = v
  def v = @v
end
O = ->(a) { a = Box.new(a.v + 1); b = "x" * 3; [a.v, b] }
p O.call(Box.new(1))

# the other forms of assignment, and an empty literal
OR = ->(a) { a ||= "n" * 2; b = [1, 2]; [a, b] }
OR.call(7)
p OR.call(nil), OR.call(5)
M = ->(a) { a, c = [a.to_s * 2, 1]; b = [1, 2]; [a, b, c] }
M.call(7)
p M.call("m")
C = ->(a) { a = a.to_s * 2 if a.is_a?(Integer); b = [1, 2]; [a, b] }
C.call("c")
p C.call(6)
W = ->(a) { i = 0; while i < 3; a = a.to_s + "x"; i += 1; end; b = [1, 2]; [a, b] }
W.call(7)
p W.call("w")
E = ->(a) { a = []; b = "x" * 3; [a, b] }
E.call(7)
p E.call("e")
I = ->(a) { a = a.filter_map { |e| e + 1 if e >= 0 }; b = "x" * 3; [a, b] }
p I.call([1, -1, 2])

# a second parameter and a post
T = ->(x, a) { a = a.to_s * 2; b = [1, 2]; [x, a, b] }
T.call(7, 7)
p T.call(1, "t")
Q = ->(*x, a) { a = a.to_s * 2; b = [1, 2]; [x, a, b] }
Q.call(7, 7)
p Q.call(1, 2, "q")
LP = lambda { |*x, a| a = a.to_s * 2; b = [1, 2]; [x, a, b] }
LP.call(7, 7)
p LP.call(1, "p")

# a block's required parameter and a lambda that only reads, as before
L = lambda { |a| a = a.to_s * 2; b = [1, 2]; [a, b] }
L.call(7)
p L.call("l")
R = ->(a) { b = [1, 2]; [a, b] }
R.call(7)
p R.call("r")
