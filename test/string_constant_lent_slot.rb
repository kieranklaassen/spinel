# A constant's String lives in a C global, as a global variable's does, and
# a parameter the callee appends to was lent a temp copy of it instead of
# the slot, so the append never reached the constant: `write(OUT, "hello")`
# into `def write(buf, s) = buf << s` left OUT empty. The C global is now
# lent as a global's is: through a direct call, a keyword and an optional
# parameter, a class and an instance method, two calls deep, a block and a
# lambda, a yield into a block that appends, and each_with_object.
# Each append is 100 bytes, so it cannot land in spare capacity by chance.
OUT = String.new
def write(buf, s) = buf << s
write(OUT, "hello ")
write(OUT, "world")
puts OUT

def gr(v) = v << "x" * 100
def kw(v:) = v << "k" * 100
def opt(a, v = nil) = v << "o" * 100
def deep(v) = gr(v)
def yl(v) = yield(v)

A = +"a"; gr(A); p A.size
B = "b".dup; kw(v: B); opt(1, B); p B.size
C = String.new("c"); 2.times { gr(C) }; p C.size
D = "d" + ""; l = -> { gr(D) }; l.call; p D.size
E = +"e"; yl(E) { |t| t << "y" * 100 }; p E.size
F = +"f"; deep(F); p F.size
G = +"g"; [1, 2].each_with_object(G) { |_, o| o << "w" * 100 }; p G.size
def tl = (gr(A); A.size)
p tl

# the other mutators land in the constant too
H = +"hello"
def chg(v) = (v.replace("jello" * 30); v.insert(0, ">"); v.gsub!("j", "J"); v.upcase!)
chg(H)
p H.size, H[0, 6]

class K
  BUF = +"k"
  def self.gr(v) = v << "q" * 100
  def self.run = (gr(BUF); yl(BUF) { |t| t.concat("z" * 100) }; BUF.size)
  def add(s) = (K.gr(BUF); BUF << s)
  def show = BUF.size
end
p K.run
K.new.add("!")
p K.new.show, K::BUF.size
module M
  S = +"m"
  def self.go = (gr(S); S.size)
end
p M.go
gr(M::S); p M::S.size

# a constant a block assigns each time round is lent inside that block
3.times do |i|
  T = +"t#{i}"
  gr(T)
  p T.size
end if ARGV.size > 5
[7].each { |i| U = +"u#{i}"; gr(U); p U.size }

# a frozen String still raises, a read is unchanged, and the slot survives
# collections
FZ = "fz"
begin; gr(FZ); rescue FrozenError => e; p e.class; end
p FZ
def rd(v) = v.size
p rd(A)
500.times { gr(F) }
p F.size

# a frozen constant handed to a proc that appends is not refused: it raises
LIT = "lit"
ap = ->(t) { t << "!" }
begin; ap.call(LIT); rescue FrozenError => e; p e.class; end
p LIT
